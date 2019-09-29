class PasswordResetsController < ApplicationController
  before_action :get_user,         only: %i[edit update]
  before_action :valid_user,       only: %i[edit update]
  before_action :check_expiration, only: %i[edit update]

  def new
  end

  def create
    email = params[:email].downcase

    @user = User.find_by(email: email)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:success] =
        'Reset instructions sent to' \
        " #{ActionController::Base.helpers.sanitize(email)}"
      redirect_to password_reset_sent_path
    else
      if email.blank?
        flash.now[:warning] = 'Please enter a valid email address'
      else
        flash.now[:warning] =
          "[#{ActionController::Base.helpers.sanitize(email)}] is not a" \
          ' registered user'
      end
      render 'new'
    end
  end

  def edit
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update(user_params)
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = 'Password has been reset'
      redirect_to tasks_path
    else
      render 'edit'
    end
  end

  # This is the page we drop users onto after they've submitted a successful
  # password reset request. This avoids confusion that could arise from
  # redirecting them to the login page or whatnot.
  def sent
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # Before filters

  def get_user
    @user = User.find_by(email: params[:email])
  end

  # Confirms a valid user.
  def valid_user
    unless @user && @user.activated? &&
           @user.authenticated?(:reset, params[:id])
      flash[:warning] = 'That password reset link was invalid. Please try' \
                        ' again.'
      redirect_to new_password_reset_path
    end
  end

  # Checks expiration of reset token.
  def check_expiration
    return unless @user.password_reset_expired?

    @user.password_reset_expired?
    flash[:warning] = 'That password reset link has expired (they expire' \
      ' after 2 hours)'
    redirect_to new_password_reset_path
  end
end
