require 'application_system_test_case'

class QuoteFeaturesTest < ApplicationSystemTestCase
  test 'verify operation of the display quotes setting' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    assert has_selector?('div#header_quote_container')

    click_link 'Settings'
    click_link 'Quotes'
    assert_current_path quotes_path

    # Disable display of quotes
    assert has_no_content?('Settings Saved')
    uncheck('display_random_quote', allow_label_click: true)
    assert has_content?('Settings Saved')

    # Verify that the quote container no longer is shown
    click_link 'logo'
    assert_current_path tasks_path
    assert_no_selector 'div#header_quote_container'

    # Now enable display of quotes
    click_link 'Settings'
    click_link 'Quotes'
    assert_current_path quotes_path

    assert has_no_content?('Settings Saved')
    check('display_random_quote', allow_label_click: true)
    assert has_content?('Settings Saved')

    # Verify that the quote container is shown again
    click_link 'logo'
    assert_current_path tasks_path
    assert_selector 'div#header_quote_container'
  end
end
