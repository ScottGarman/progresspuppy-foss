require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:donpdonp)
  end

  test 'password resets' do
    get new_password_reset_path
    assert_response :success
    assert_template 'password_resets/new'

    # Reset request with an invalid email
    post password_resets_path, params: { email: '' }
    assert_not flash.empty?
    assert_select 'div.alert-warning', 'Please enter a valid email address'
    assert_template 'password_resets/new'

    # Reset request with the email address of an invalid user
    post password_resets_path, params: { email: 'bogus@example.com' }
    assert_not flash.empty?
    assert_select 'div.alert-warning', '[bogus@example.com] is not a ' \
                                       'registered user'
    assert_template 'password_resets/new'

    # Reset request with a valid email
    post password_resets_path,
         params: { email: @user.email }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not flash.empty?
    assert_redirected_to password_reset_sent_path
    follow_redirect!
    assert_template 'password_resets/sent'
    assert_select 'div.alert-success', 'Reset instructions sent to ' \
                                       "#{user.email}"

    # Reset link using wrong email, right token
    get edit_password_reset_path(user.reset_token, email: '')
    assert_redirected_to new_password_reset_path
    assert_not flash.empty?
    follow_redirect!
    assert_response :success
    assert_template 'password_resets/new'
    assert_select 'div.alert-warning', 'That password reset link was ' \
                                       'invalid. Please try again or contact ' \
                                       'support for help.'

    # Reset link from an inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to new_password_reset_path
    assert_not flash.empty?
    follow_redirect!
    assert_response :success
    assert_select 'div.alert-warning', 'That password reset link was ' \
                                       'invalid. Please try again or contact ' \
                                       'support for help.'
    user.toggle!(:activated)

    # Reset link using right email, wrong token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to new_password_reset_path
    assert_not flash.empty?
    follow_redirect!
    assert_response :success
    assert_select 'div.alert-warning', 'That password reset link was ' \
                                       'invalid. Please try again or contact ' \
                                       'support for help.'

    # Reset link using right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert flash.empty?
    assert_response :success
    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', user.email

    # Invalid password & confirmation
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: 'foobaz',
                            password_confirmation: 'blah' } }
    assert_select 'p#password_error_msg', /is too short/

    # Empty password
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: '',
                            password_confirmation: '' } }
    assert_select 'p#password_error_msg', /can't be empty/

    # Valid password & confirmation
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: 'foobarbaz123',
                            password_confirmation: 'foobarbaz123' } }
    assert_nil user.reload.reset_digest
    assert logged_in?
    assert_not flash.empty?
    assert_redirected_to tasks_path
    follow_redirect!
    assert_response :success
    assert_select 'div.alert-success', 'Password has been reset'
  end

  test 'expired token' do
    get new_password_reset_path
    post password_resets_path,
         params: { email: @user.email }

    @user = assigns(:user)
    # Reset tokens expire after 2 hours
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
          params: { email: @user.email,
                    user: { password: 'foobarbaz123',
                            password_confirmation: 'foobarbaz123' } }
    assert_not flash.empty?
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select 'div.alert-warning', 'That password reset link has expired ' \
                                       '(they expire after 2 hours)'
  end
end
