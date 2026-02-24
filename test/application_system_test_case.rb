require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Set the driver path before driven_by so Rails' preload step skips
  # Selenium Manager (which hangs on this system).
  Selenium::WebDriver::Chrome::Service.driver_path =
    ENV.fetch('CHROMEDRIVER_BIN', '/home/sgarman/bin/chromedriver')

  # For headless mode (CI), set HEADLESS=1: HEADLESS=1 bin/rails test:system
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400] do |driver_option|
    driver_option.add_argument('--headless=new') if ENV['HEADLESS'] || ENV['CI']
    driver_option.add_argument('--disable-gpu')
    driver_option.add_argument('--no-sandbox')
    driver_option.binary = ENV.fetch('CHROME_BIN', '/usr/bin/google-chrome-stable')
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
