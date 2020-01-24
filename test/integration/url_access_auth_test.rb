require 'test_helper'

class UrlAccessAuthTest < ActionDispatch::IntegrationTest
  test 'account activation controller urls that should be publicly' \
       ' accessible, not requiring authentication' do
    # edit
    get edit_account_activation_url(1), params: { email: 'user@example.com' }
    assert_redirected_to login_path

    # resend
    get resend_activation_url, params: { email: 'user@example.com' }
    assert_redirected_to login_path
  end

  test 'password reset controller urls that should be publicly accessible,' \
       ' not requiring authentication' do
    # new
    get new_password_reset_url
    assert_response :success
    assert_template 'password_resets/new'

    # create
    post password_resets_url, params: { email: 'user@example.com' }
    assert_response :success
    assert_template 'password_resets/new'
  end

  test 'password reset controller urls that should not be accessible to' \
       ' unauthenticated users' do
    # edit using a bogus password reset link
    get edit_password_reset_url(1)
    assert_redirected_to new_password_reset_path
    assert_not flash.empty?
    follow_redirect!
    assert_response :success
    assert_template 'password_resets/new'
    assert_select 'div.alert-warning', 'That password reset link was' \
                  ' invalid. Please try again.' \

    # update using a bogus password reset link
    patch password_reset_url(1)
    assert_redirected_to new_password_reset_path
    assert_not flash.empty?
    follow_redirect!
    assert_response :success
    assert_template 'password_resets/new'
    assert_select 'div.alert-warning', 'That password reset link was' \
                  ' invalid. Please try again.' \
  end

  test 'quote controller urls that should not be accessible to' \
       ' unauthenticated users' do
    # index
    get quotes_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # show
    get quote_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # create
    post quotes_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # edit
    get edit_quote_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # update
    patch quote_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # destroy
    delete quote_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'settings urls that should not be accessible to unauthenticated users' do
    # edit
    get settings_edit_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # toggle_display_quotes
    post settings_toggle_display_quotes_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'session controller urls that should be publicly accessible, not' \
       ' requiring authentication' do
    # new (via login)
    get login_url
    assert_response :success
    assert_template 'sessions/new'

    # create (via login)
    post login_url, params: { email: 'user@example.com',
                              password: 'foobarbaz123' }
    assert_response :success
  end

  test 'session controller urls that should not be accessible to' \
       ' unauthenticated users' do
    # destroy (via logout)
    delete logout_url
    assert_redirected_to login_url
    follow_redirect!
    assert_template 'sessions/new'
  end

  test 'task category controller urls that should not be accessible to' \
       ' unauthenticated users' do
    # index
    get task_categories_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # create
    post task_categories_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # edit
    get edit_task_category_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # update
    patch task_category_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # destroy
    delete task_category_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'task controller urls that should not be accessible to unauthenticated' \
       ' users' do
    # index (via root)
    get root_url
    assert_redirected_to login_url
    follow_redirect!
    assert_template 'sessions/new'

    # index
    get tasks_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # upcoming
    get upcoming_tasks_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # search
    get search_tasks_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # create
    post tasks_url
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # show
    get task_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # edit
    get edit_task_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # update
    patch task_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'

    # destroy
    delete task_url(1)
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'user controller urls that should be publicly accessible, not' \
       ' requiring authentication' do
    # new
    get new_user_url
    assert_response :success
    assert_template 'users/new'

    # new (via /signup)
    get signup_url
    assert_response :success
    assert_template 'users/new'

    # create (via /signup)
    post signup_url, params: { user: { first_name: 'Example',
                                       last_name: 'User',
                                       email: 'user@example.com',
                                       password: 'foobarbaz123',
                                       password_confirmation: 'foobarbaz123' } }
    assert_redirected_to thanks_path

    # thanks (via /thanks)
    get thanks_url
    assert_response :success
    assert_template 'users/thanks'
  end

  test 'user controller urls that should not be accessible to unauthenticatd' \
       ' users' do
    # edit
    get user_profile_path
    assert_redirected_to login_path

    # update
    patch user_url(1)
    assert_redirected_to login_path

    # destroy
    delete user_url(1)
    assert_redirected_to login_path
  end

  test 'pages controller urls that should be publicly accessible, not' \
       ' requiring authentication' do
    # Terms of Service page
    get terms_of_service_url
    assert_response :success
    assert_template 'pages/terms_of_service'
  end
end
