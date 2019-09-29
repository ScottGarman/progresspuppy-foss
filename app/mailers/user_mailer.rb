class UserMailer < ApplicationMailer
  def account_activation(user)
    @user = user
    mail to: user.email,
         subject: 'ProgressPuppy - FOSS Edition account activation'
  end

  def password_reset(user)
    @user = user
    mail to: user.email,
         subject: 'ProgressPuppy - FOSS Edition password reset'
  end
end
