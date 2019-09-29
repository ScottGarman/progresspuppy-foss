require 'test_helper'

class SettingsOperationsTest < ActionDispatch::IntegrationTest
  test 'user can modify their display_quotes setting' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View Quote Settings
    get quotes_path
    assert_response :success
    assert donpdonp.setting.display_quotes

    # Turn display_quotes off
    post settings_toggle_display_quotes_path, xhr: true
    assert_not donpdonp.setting.reload.display_quotes

    # Turn display_quotes back on again
    post settings_toggle_display_quotes_path, xhr: true
    assert donpdonp.setting.reload.display_quotes
  end

  test 'ensure users cannot modify the display_quotes setting of another' \
       ' user' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp logs in and confirms his display_quotes setting is true
    log_in_as(donpdonp)
    get quotes_path
    assert_response :success
    assert donpdonp.setting.display_quotes

    # onewheelskyward logs in and tries to modify donpdonp's quote
    # Since there's no user id used in the quote settings path, all we're doing
    # here is having ows modify his display_quotes setting and verifying that it
    # hasn't changed the display_quotes setting of donpdonp
    log_in_as(ows)
    get quotes_path
    assert_response :success
    assert ows.setting.display_quotes

    post settings_toggle_display_quotes_path, xhr: true
    assert_not ows.setting.reload.display_quotes

    assert donpdonp.setting.reload.display_quotes
  end
end
