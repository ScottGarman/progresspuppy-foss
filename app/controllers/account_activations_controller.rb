class AccountActivationsController < ApplicationController
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = 'Thanks - your account has now been activated!'
      redirect_to tasks_path
    else
      flash[:danger] = 'That activation link was invalid or has already been' \
                       ' used'
      redirect_to login_path
    end
  end

  def resend
    @user = User.find_by(email: params[:email])
    if @user && !@user.activated?
      @user.resend_activation_email
      flash[:success] = "New activation link sent to #{@user.email}. Please " \
                        ' check your email to activate your account.'
    end
    redirect_to login_path
  end
end
