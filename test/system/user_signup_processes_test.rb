require 'application_system_test_case'

class UserSignupProcessesTest < ApplicationSystemTestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    visit signup_url
    assert_no_selector 'p#first_name_error_msg'
    assert_no_selector 'p#last_name_error_msg'
    assert_no_selector 'p#email_error_msg'
    assert_no_selector 'p#password_error_msg'
    assert_no_selector 'p#accepted_tos_error_msg'

    assert_no_difference 'User.count' do
      fill_in 'user[first_name]', with: ''
      fill_in 'user[last_name]', with: ''
      fill_in 'user[email]', with: 'user@invalid'
      fill_in 'user[password]', with: 'foo'
      fill_in 'user[password_confirmation]', with: 'bar'
      click_button 'Create my account'
    end

    assert_current_path signup_path
    assert_selector 'p#first_name_error_msg', count: 1
    assert has_content?("First name can't be blank")
    assert_selector 'p#last_name_error_msg', count: 1
    assert has_content?("Last name can't be blank")
    assert_selector 'p#email_error_msg', count: 1
    assert has_content?('Email is invalid')
    assert_selector 'p#password_error_msg', count: 1
    assert has_content?('Password is too short (minimum is 10 characters)')
    assert has_content?("Password confirmation doesn't match Password")
    assert_selector 'p#accepted_tos_error_msg', count: 1
    assert has_content?('The Terms of Service, Privacy Policy, and' \
                             ' Cookie Policy must be accepted')
  end

  test 'signup attempt without accepting ToS/Privacy Policy' do
    visit signup_url
    assert_no_selector 'p#accepted_tos_error_msg'

    assert_no_difference 'User.count' do
      fill_in 'user[first_name]', with: 'Example'
      fill_in 'user[last_name]', with: 'User'
      fill_in 'user[email]', with: 'user@example.com'
      fill_in 'user[password]', with: 'foobarbaz123'
      fill_in 'user[password_confirmation]', with: 'foobarbaz123'
      click_button 'Create my account'
    end

    assert_current_path signup_path
    assert_selector 'p#accepted_tos_error_msg', count: 1
    assert has_content?('The Terms of Service, Privacy Policy, and' \
                             ' Cookie Policy must be accepted')
  end

  test 'valid signup information with account activation' do
    assert_nil User.find_by_email('user@example.com')

    visit signup_url

    assert_difference 'User.count', 1 do
      fill_in 'user[first_name]', with: 'Example'
      fill_in 'user[last_name]', with: 'User'
      fill_in 'user[email]', with: 'user@example.com'
      fill_in 'user[password]', with: 'foobarbaz123'
      fill_in 'user[password_confirmation]', with: 'foobarbaz123'
      # I can't seem to get this to work, and it may be a bug that's
      # Chrome-specific:
      #check 'user_accepted_tos'
      # So let's hit it with a hammer:
      execute_script("$('#user_accepted_tos').click()")
      click_button 'Create my account'
    end

    assert_current_path thanks_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    activation_token = email.text_part.body.decoded
                            .match(%r{http.*\/account_activations\/(.*)\/edit})[1]
    assert_not_nil activation_token

    user = User.find_by_email('user@example.com')
    assert_not user.activated?
    assert_not_nil user.accepted_tos_at

    # Check the email that was sent
    assert_equal user.email, email['to'].to_s
    assert_equal 'ProgressPuppy - FOSS Edition account activation', email.subject

    # Try to log in before activation
    visit login_url

    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert_current_path login_path
    assert has_content?('We need to verify your email address before' \
                             ' you can log in. Please check your email for' \
                             ' the activation link.')

    # Use an invalid activation token
    visit edit_account_activation_url('invalid token', email: user.email)
    assert_current_path login_path
    assert has_content?('That activation link was invalid or has' \
                             ' already been used')

    # Use a valid activation token, but with a wrong email address
    visit edit_account_activation_url(activation_token, email: 'wrong')
    assert_current_path login_path
    assert has_content?('That activation link was invalid or has' \
                             ' already been used')

    # Valid activation token
    visit edit_account_activation_url(activation_token, email: user.email)
    assert_current_path tasks_path
    assert has_content?('Thanks - your account has now been activated!')
    assert user.reload.activated?

    # Logged-in users trying to access the signup page should get redirected to
    # the root path
    visit signup_path
    assert_current_path root_path

    # Now log out and log back in normally
    click_link 'Settings'
    assert has_selector?(:link_or_button, 'Log out')
    click_link 'Log out'
    assert_current_path login_path

    visit login_path
    assert_current_path login_path

    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert_current_path tasks_path
  end

  test 'resend account activation' do
    assert_nil User.find_by_email('user@example.com')

    visit signup_url

    assert_difference 'User.count', 1 do
      fill_in 'user[first_name]', with: 'Example'
      fill_in 'user[last_name]', with: 'User'
      fill_in 'user[email]', with: 'user@example.com'
      fill_in 'user[password]', with: 'foobarbaz123'
      fill_in 'user[password_confirmation]', with: 'foobarbaz123'
      # I can't seem to get this to work, and it may be a bug that's
      # Chrome-specific:
      #check 'user_accepted_tos'
      # So let's hit it with a hammer:
      execute_script("$('#user_accepted_tos').click()")
      click_button 'Create my account'
    end

    assert_current_path thanks_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    activation_token_old = email.text_part.body.decoded
                            .match(%r{http.*\/account_activations\/(.*)\/edit})[1]
    assert_not_nil activation_token_old

    user = User.find_by_email('user@example.com')
    assert_not user.activated?
    assert_not_nil user.accepted_tos_at

    # Check the email that was sent
    assert_equal user.email, email['to'].to_s
    assert_equal 'ProgressPuppy - FOSS Edition account activation', email.subject

    # Try to log in, and request a new activation link
    visit login_url
    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert has_content?('We need to verify your email address before' \
                             ' you can log in. Please check your email for' \
                             ' the activation link.')
    click_link 'click here'

    assert has_content?("New activation link sent to #{user.email}." \
                             ' Please check your email to activate your' \
                             ' account')

    assert_equal 2, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    activation_token = email.text_part.body.decoded
                            .match(%r{http.*\/account_activations\/(.*)\/edit})[1]
    assert_not_nil activation_token

    # The old activation url should no longer work
    visit edit_account_activation_url(activation_token_old, email: user.email)
    assert_current_path login_path
    assert has_content?('That activation link was invalid or has already' \
                             ' been used')
    assert_not user.reload.activated?

    # But the new one should work
    visit edit_account_activation_url(activation_token, email: user.email)
    assert_current_path tasks_path
    assert has_content?('Thanks - your account has now been activated!')
    assert user.reload.activated?
  end

  test 'signup new user and just visit every separate page on the site' do
    assert_nil User.find_by_email('user@example.com')

    visit signup_url

    assert_difference 'User.count', 1 do
      fill_in 'user[first_name]', with: 'Example'
      fill_in 'user[last_name]', with: 'User'
      fill_in 'user[email]', with: 'user@example.com'
      fill_in 'user[password]', with: 'foobarbaz123'
      fill_in 'user[password_confirmation]', with: 'foobarbaz123'
      # I can't seem to get this to work, and it may be a bug that's
      # Chrome-specific:
      #check 'user_accepted_tos'
      # So let's hit it with a hammer:
      execute_script("$('#user_accepted_tos').click()")
      click_button 'Create my account'
    end

    assert_current_path thanks_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    activation_token = email.text_part.body.decoded
                            .match(%r{http.*\/account_activations\/(.*)\/edit})[1]
    assert_not_nil activation_token

    user = User.find_by_email('user@example.com')
    assert_not user.activated?
    assert_not_nil user.accepted_tos_at

    # Check the email that was sent
    assert_equal user.email, email['to'].to_s
    assert_equal 'ProgressPuppy - FOSS Edition account activation', email.subject

    # Activate the account
    visit edit_account_activation_url(activation_token, email: user.email)
    assert_current_path tasks_path
    assert has_content?('Thanks - your account has now been activated!')
    assert user.reload.activated?

    # Visit all Task related urls
    click_link 'Upcoming Tasks'
    assert_current_path upcoming_tasks_path
    click_link 'Search'
    assert_current_path search_tasks_path

    # Visit all the links in the dropdown menu
    click_link 'Settings'
    assert has_selector?(:link_or_button, 'User Profile')
    click_link 'User Profile'
    assert_current_path user_profile_path
    assert has_content?('User Profile')
    click_link 'Settings'
    assert has_selector?(:link_or_button, 'Task Categories')
    click_link 'Task Categories'
    assert_current_path task_categories_path
    assert has_content?('Manage Task Categories')
    assert has_content?('Define a New Task Category')
    assert has_content?('Your Task Categories')
    click_link 'Settings'
    assert has_selector?(:link_or_button, 'Quotes')
    click_link 'Quotes'
    assert_current_path quotes_path
    assert has_content?('Manage Quotes')
    assert has_content?('Quote Settings')
    assert has_content?('Add a New Quote')
    assert has_content?('Your Quotes')
  end
end
