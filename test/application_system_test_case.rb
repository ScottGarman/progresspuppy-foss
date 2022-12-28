require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Configuring capybara this way is now deprecated:
  #driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  #driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new app, browser: :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu])
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
