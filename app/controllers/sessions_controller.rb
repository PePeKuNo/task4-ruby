class SessionsController < ApplicationController
  # IMPORTANT: Skip authentication for login form (new) and login action (create)
  # NOTA BENE: Must be HERE, not in ApplicationController, so Rails knows which :new/:create to skip
  skip_before_action :require_login, only: [:new, :create], raise: false
  skip_before_action :check_user_status, only: [:new, :create], raise: false

  # GET /login - Show login form
  def new
    # If already logged in, redirect to admin panel
    redirect_to admin_path if logged_in?
  end

  # POST /login - Process login
  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    # NOTE: authenticate is provided by has_secure_password
    # It returns false if password doesn't match or user is nil
    if user&.authenticate(params[:password])
      # Check if user is blocked BEFORE creating session
      if user.blocked?
        flash.now[:alert] = 'Your account has been blocked. Please contact administrator.'
        render :new, status: :unprocessable_entity
        return
      end

      # IMPORTANT: Create session
      session[:user_id] = user.id
      # Update last_seen on login
      user.touch_last_seen!
      flash[:notice] = 'Successfully logged in.'
      redirect_to admin_path
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout - Destroy session
  def destroy
    session[:user_id] = nil
    flash[:notice] = 'Successfully logged out.'
    redirect_to login_path
  end
end