require "application_system_test_case"

class QuoteFeaturesTest < ApplicationSystemTestCase
  def log_in_as(user)
    visit login_url
    assert_current_path login_path

    fill_in 'email', with: user.email
    fill_in 'password', with: 'foobarbaz123'
    click_button 'Log in'

    assert_current_path tasks_path
  end

  test 'verify operation of the display quotes setting' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    assert page.has_selector?('div#header_quote_container')

    click_link 'Settings'
    click_link 'Quotes'
    assert_current_path quotes_path

    # Disable display of quotes
    assert page.has_no_content?('Settings Saved')
    #uncheck 'display'
    page.execute_script("$('#display').click()")
    assert page.has_content?('Settings Saved')

    # Verify that the quote container no longer is shown
    click_link 'logo'
    assert_current_path tasks_path
    sleep 1
    page.assert_no_selector 'div#header_quote_container'

    # Now enable display of quotes
    click_link 'Settings'
    click_link 'Quotes'
    assert_current_path quotes_path

    assert page.has_no_content?('Settings Saved')
    #uncheck 'display'
    execute_script("$('#display').click()")
    assert page.has_content?('Settings Saved')

    # Verify that the quote container is shown again
    click_link 'logo'
    assert_current_path tasks_path
    sleep 1
    assert_selector 'div#header_quote_container'
  end
end
