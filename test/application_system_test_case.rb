require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.register_driver :chrome do |app|
    # rubocop:disable Layout/HashAlignment
    Capybara::Selenium::Driver.new app, browser: :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu])
    # rubocop:enable Layout/HashAlignment
  end

  Capybara.javascript_driver = :chrome

  def log_in_as(user)
    visit login_url
    assert_current_path login_path

    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert_current_path tasks_path
  end
end
