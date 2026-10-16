class RegistrationsController < ApplicationController
  # IMPORTANT: Skip authentication for registration form (new) and registration action (create)
  # NOTA BENE: Must be HERE, not in ApplicationController, so Rails knows which :new/:create to skip
  skip_before_action :require_login, only: [:new, :create], raise: false
  skip_before_action :check_user_status, only: [:new, :create], raise: false

  # GET /register - Show registration form
  def new
    # If already logged in, redirect to admin panel
    redirect_to admin_path if logged_in?
    @user = User.new
  end

  # POST /register - Process registration
  def create
    @user = User.new(user_params)

    # NOTE: Email is downcased for case-insensitive uniqueness
    @user.email = @user.email.downcase.strip

    # IMPORTANT: New users are registered as 'active' by default
    @user.status = 'active'
    @user.last_seen = Time.current

    if @user.save
      # IMPORTANT: Auto-login after successful registration
      session[:user_id] = @user.id
      flash[:notice] = 'Registration successful! Welcome to the admin panel.'
      redirect_to admin_path
    else
      # NOTE: Render new with errors
      flash.now[:alert] = 'Registration failed. Please check the errors below.'
      render :new, status: :unprocessable_entity
    end
  end

  private

  # NOTE: Strong parameters for user registration
  def user_params
    params.require(:user).permit(:full_name, :email, :job_position, :password, :password_confirmation)
  end
end