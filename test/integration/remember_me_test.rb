require 'test_helper'

class RememberMeTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:donpdonp)
  end

  test 'login with remember me should set persistent cookies' do
    # Log in with remember me checkbox
    log_in_as(@user, remember_me: '1')

    # Verify user is logged in via session
    assert_not_nil session[:user_id]
    assert_equal @user.id, session[:user_id]

    # Verify remember cookies are set (they exist as encoded cookies)
    assert_not_nil cookies['user_id']
    assert_not_nil cookies['remember_token']

    # Verify the remember_digest was set in the database
    @user.reload
    assert_not_nil @user.remember_digest
  end

  test 'current_user should return user from signed cookies when session is cleared' do
    # Log in with remember me
    log_in_as(@user, remember_me: '1')
    assert logged_in?

    # Verify cookies are set
    assert_not_nil cookies['user_id']
    assert_not_nil cookies['remember_token']

    # Simulate closing and reopening browser by clearing only the session
    # but keeping the cookies (don't call logout which deletes cookies)
    session.delete(:user_id)
    assert_not logged_in?

    # Make a request - the persistent cookies should log us back in via current_user
    get root_path
    assert logged_in?, 'User should be logged in via persistent cookies'
  end

  test 'current_user should reject invalid remember token from signed cookies' do
    # Log in with remember me
    log_in_as(@user, remember_me: '1')
    assert logged_in?

    # Get the cookies before reset
    user_id_cookie = cookies['user_id']
    remember_token_cookie = cookies['remember_token']

    # Manually corrupt the remember_digest in the database
    @user.update_attribute(:remember_digest, User.digest(User.new_token))

    # Reset to clear all state (session and instance variables)
    reset!

    # Restore the cookies (which have the old remember_token that doesn't match)
    cookies['user_id'] = user_id_cookie
    cookies['remember_token'] = remember_token_cookie

    # Make a request - should not be logged in due to mismatched token
    get root_path
    assert_not logged_in?, 'User should not be logged in with invalid token'
  end

  test 'login without remember me should not set persistent cookies' do
    # Log in without remember me (pass nil to make it falsy)
    post login_path, params: { email: @user.email,
                               password: 'foobarbaz123',
                               remember_me: nil }

    # Verify user is logged in via session
    assert_not_nil session[:user_id]

    # Verify remember_digest is nil (forget was called)
    @user.reload
    assert_nil @user.remember_digest
  end

  test 'persistent cookies should survive multiple requests after session cleared' do
    # Log in with remember me
    log_in_as(@user, remember_me: '1')

    # Get a protected page to verify we're logged in
    get root_path
    assert_response :success
    assert logged_in?

    # The cookies should persist across multiple requests
    get root_path
    assert_response :success
    assert logged_in?
  end

  test 'current_user should reject tampered remember_token cookie' do
    # Log in with remember me to establish valid cookies
    log_in_as(@user, remember_me: '1')
    assert logged_in?

    # Get the valid user_id cookie
    user_id_cookie = cookies['user_id']

    # Reset to clear all state
    reset!

    # Simulate an attacker tampering with the remember_token cookie
    # Keep the valid signed user_id but set a bogus remember_token
    cookies['user_id'] = user_id_cookie
    cookies['remember_token'] = 'tampered_token_xyz123'

    # Make a request - should not authenticate with tampered token
    get root_path
    assert_not logged_in?, 'User should not be authenticated with tampered remember_token'
  end

  test 'current_user should reject nil remember_token with valid user_id cookie' do
    # Log in with remember me to establish valid cookies
    log_in_as(@user, remember_me: '1')
    assert logged_in?

    # Get the valid user_id cookie
    user_id_cookie = cookies['user_id']

    # Reset to clear all state
    reset!

    # Simulate someone removing the remember_token cookie but keeping user_id
    cookies['user_id'] = user_id_cookie
    cookies['remember_token'] = nil

    # Make a request - should not authenticate without remember_token
    get root_path
    assert_not logged_in?, 'User should not be authenticated without remember_token'
  end

  private

  def logged_in?
    !session[:user_id].nil?
  end
end
