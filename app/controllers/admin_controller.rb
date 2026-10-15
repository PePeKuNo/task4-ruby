class AdminController < ApplicationController
  # NOTE: All actions require authentication (handled by ApplicationController)

  # GET /admin - User management table with toolbar
  def index
    # NOTE: Get all users sorted by last_seen (requirement: data sorted by last login time)
    @users = User.ordered_by_last_seen

    # NOTE: For the chat feature (parts 2 and 3) - get recent messages
    @chat_messages = ChatMessage.includes(:user).order(created_at: :desc).limit(50).reverse
    @chat_message = ChatMessage.new
  end

  # POST /admin/bulk_action - Handle toolbar actions (block, unblock, delete)
  def bulk_action
    # NOTE: Get selected user IDs from checkboxes
    user_ids = params[:user_ids] || []
    action = params[:bulk_action]

    # Validate input
    if user_ids.empty?
      flash[:alert] = 'No users selected.'
      redirect_to admin_path and return
    end

    if action.blank?
      flash[:alert] = 'No action selected.'
      redirect_to admin_path and return
    end

    # IMPORTANT: Find selected users (including current user - admins can delete themselves)
    users = User.where(id: user_ids)
    current_user_id = current_user.id

    # NOTE: Count for success message
    affected_count = 0

    case action
    when 'block'
      # Block selected users
      affected_count = users.update_all(status: 'blocked')
      flash[:notice] = "Successfully blocked #{affected_count} user(s)."

    when 'unblock'
      # Unblock selected users
      affected_count = users.update_all(status: 'active')
      flash[:notice] = "Successfully unblocked #{affected_count} user(s)."

    when 'delete'
      # IMPORTANT: Delete selected users (hard delete, not soft delete)
      # NOTA BENE: Admins CAN delete themselves (requirement: "admin ability to delete themselves is very real")
      affected_count = users.count
      users.destroy_all
      flash[:notice] = "Successfully deleted #{affected_count} user(s)."

      # If current user deleted themselves, destroy session and redirect to login
      if user_ids.include?(current_user_id.to_s)
        session[:user_id] = nil
        flash[:alert] = 'You have deleted your own account. Redirected to login page.'
        redirect_to login_path and return
      end

    else
      flash[:alert] = 'Invalid action.'
    end

    redirect_to admin_path
  end
end