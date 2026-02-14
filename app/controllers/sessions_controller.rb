class SessionsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user&.authenticate(params[:password])
      if @user.activated?
        log_in @user
        params[:remember_me] ? remember(@user) : forget(@user)
        redirect_back_or tasks_url
      else
        click_here_link = '<a href="' \
                          "#{resend_activation_url(email: @user.email)}" \
                          '">click here</a>'
        flash[:warning] = 'We need to verify your email address before you ' \
                          'can log in. Please check your email for the ' \
                          "activation link. If it's been a few minutes, " \
                          "#{click_here_link} to send a new activation email."
        render 'new', status: :unprocessable_entity
      end
    else
      flash.now[:warning] = 'Invalid email/password combination'
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to login_url
  end
end
