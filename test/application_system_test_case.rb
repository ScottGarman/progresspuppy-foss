require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Set CHROMEDRIVER_BIN to bypass Selenium Manager's driver auto-detection,
  # which can hang on some systems.
  Selenium::WebDriver::Chrome::Service.driver_path = ENV['CHROMEDRIVER_BIN'] if ENV['CHROMEDRIVER_BIN']

  # For headless mode (CI), set HEADLESS=1: HEADLESS=1 bin/rails test:system
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400] do |driver_option|
    driver_option.add_argument('--headless=new') if ENV['HEADLESS'] || ENV['CI']
    driver_option.add_argument('--disable-gpu')
    driver_option.add_argument('--no-sandbox')
  end

  def log_in_as(user)
    visit login_url
    assert_current_path login_path

    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert_current_path tasks_path
  end
end
