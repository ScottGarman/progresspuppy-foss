class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[edit update destroy]
  before_action :correct_user,   only: %i[update]
  before_action :admin_user,     only: :destroy

  def new
    # Logged-in users get redirected to the root_url
    redirect_to root_path if current_user.present?
    @user = User.new
  end

  def create
    # Logged-in users get redirected to their profile page
    redirect_to user_profile_path if current_user.present?
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      redirect_to thanks_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = User.find_by_id(params[:id])
    if @user.nil?
      flash[:danger] = 'Update failed: User not found'
      redirect_to(root_path) && return
    end

    if @user.update(user_params)
      flash[:success] = 'Profile updated'
      redirect_to user_profile_path
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find_by_id(params[:id])
    if user.nil?
      flash[:danger] = 'Deleting User failed: user not found'
      redirect_to(root_path) && return
    end

    user.destroy
    flash[:success] = 'User deleted'
    redirect_to users_url
  end

  # Static page with user instructions to activate account
  def thanks
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password,
                                 :password_confirmation, :time_zone,
                                 :accepted_tos)
  end

  # Before filters

  # Confirms the correct user.
  def correct_user
    @user = User.find_by_id(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end
end
