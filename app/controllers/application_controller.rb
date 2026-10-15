class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # IMPORTANT: Add session helper methods for current_user
  helper_method :current_user, :logged_in?

  # NOTE: Skip authentication for registration and login pages
  # NOTA BENE: These are the ONLY actions accessible without authentication
  skip_before_action :require_login, only: [:new, :create], raise: false
  skip_before_action :check_user_status, only: [:new, :create], raise: false

  # IMPORTANT: Before each request (except registration/login), check if user exists and isn't blocked
  # If user account is blocked or deleted, redirect to login page
  before_action :require_login
  before_action :check_user_status

  private

  # NOTE: Get current user from session
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # NOTE: Check if user is logged in
  def logged_in?
    current_user.present?
  end

  # IMPORTANT: Require login for all actions except registration/login
  def require_login
    unless logged_in?
      flash[:alert] = 'You must be logged in to access this page.'
      redirect_to login_path
    end
  end

  # IMPORTANT: Check if current user exists and is not blocked
  # NOTA BENE: This runs on EVERY request except registration/login
  # If user is blocked or deleted (not found), destroy session and redirect to login
  def check_user_status
    return unless logged_in?

    # NOTE: Reload user to get latest status (in case it was changed by another admin)
    user = User.find_by(id: session[:user_id])

    if user.nil?
      # User was deleted - destroy session and redirect
      session[:user_id] = nil
      flash[:alert] = 'Your account has been deleted. Please register again.'
      redirect_to login_path
    elsif user.blocked?
      # User is blocked - destroy session and redirect
      session[:user_id] = nil
      flash[:alert] = 'Your account has been blocked. Please contact administrator.'
      redirect_to login_path
    else
      # User is active - update last_seen on each request (activity tracking)
      user.touch_last_seen!
    end
  end
end