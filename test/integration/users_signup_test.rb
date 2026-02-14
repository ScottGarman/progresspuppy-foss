require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post signup_path, params: { user: { first_name: '',
                                          last_name: '',
                                          email: 'user@invalid',
                                          password: 'foo',
                                          password_confirmation: 'bar',
                                          accepted_tos: '0' } }
    end
    assert_template 'users/new'
    assert_select 'p#first_name_error_msg', /can't be blank/
    assert_select 'p#last_name_error_msg', /can't be blank/
    assert_select 'p#email_error_msg', /is invalid/
    assert_select 'p#password_error_msg', /is too short/
    assert_select 'p#accepted_tos_error_msg', /must be accepted/
  end

  test 'signup attempt without accepting ToS/Privacy Policy' do
    get signup_path
    assert_no_difference 'User.count' do
      post signup_path, params: { user: { first_name: 'Example',
                                          last_name: 'User',
                                          email: 'user@example.com',
                                          password: 'foobarbaz123',
                                          password_confirmation: 'barbarbaz',
                                          accepted_tos: '0' } }
    end
    assert_template 'users/new'
    assert_select 'p#accepted_tos_error_msg', /must be accepted/
  end

  test 'valid signup information with account activation' do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { first_name: 'Example',
                                         last_name: 'User',
                                         email: 'user@example.com',
                                         password: 'foobarbaz123',
                                         password_confirmation: 'foobarbaz123',
                                         accepted_tos: '1' } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    assert_not_nil user.activation_token
    assert_not_nil user.accepted_tos_at

    # Try to log in before activation
    log_in_as(user)
    assert_not logged_in?

    # Use an invalid activation token
    get edit_account_activation_path('invalid token', email: user.email)
    assert_not logged_in?

    # Use a valid activation token, but with a wrong email address
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not logged_in?

    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'tasks/index'
    assert logged_in?

    # Now log out and log back in normally
    delete logout_path
    follow_redirect!
    assert_template 'sessions/new'
    assert_not logged_in?

    get login_path
    assert_template 'sessions/new'
    post login_path, params: { email: 'user@example.com',
                               password: 'foobarbaz123' }
    follow_redirect!
    assert_template 'tasks/index'
  end

  test 'resend account activation' do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {
        user: { first_name: 'Example',
                last_name: 'User',
                email: 'user@example.com',
                password: 'foobarbaz123',
                password_confirmation: 'foobarbaz123' }
      }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_equal user.first_name, 'Example'
    assert user.valid?
    assert_not user.activated?
    assert_not_nil user.activation_token
    stale_activation_token = user.activation_token

    get resend_activation_path(email: user.email)
    user = assigns(:user)
    follow_redirect!
    assert_template 'user_mailer/account_activation'
    assert_equal 2, ActionMailer::Base.deliveries.size

    # Trying to use the first activation_token should fail
    get edit_account_activation_path(stale_activation_token, email: user.email)
    assert_redirected_to login_url
    follow_redirect!
    assert_template 'sessions/new'
    assert_not user.reload.activated?

    # But using the most recent activation token should work
    get edit_account_activation_path(user.reload.activation_token,
                                     email: user.email)
    follow_redirect!
    assert_template 'tasks/index'
    assert user.reload.activated?
    assert logged_in?
  end

  test 'resend account activation with invalid data' do
    # Resending without specifying the email
    get resend_activation_path
    follow_redirect!
    assert_template 'sessions/new'

    # Resending and specifying an already-activated user email
    activated_user = users(:donpdonp)
    get resend_activation_path, params: { email: activated_user.email }
    follow_redirect!
    assert_template 'sessions/new'
  end
end
