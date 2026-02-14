require 'application_system_test_case'

class QuoteFeaturesTest < ApplicationSystemTestCase
  test 'verify operation of the display quotes setting' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    assert has_selector?('div#header_quote_container')

    click_button 'Settings'
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
    click_button 'Settings'
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

  test 'successfully editing a quote shows flash alert' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    visit quotes_url

    # Create a quote to edit
    fill_in 'quote_quotation', with: 'Original quote'
    fill_in 'quote_source', with: 'Original source'
    click_button 'Save'
    assert has_content?('New quote created')

    quote = donpdonp.quotes.first

    # Click edit on the quote
    find('img.quote-edit-icon').click

    within "#editable_quote_#{quote.id}" do
      fill_in 'quote_quotation', with: 'Updated quote'
      click_button 'Save'
    end

    # Flash alert should appear next to the "Your Quotes" heading
    assert has_content?('Quote updated')

    # The quote should be in display mode with the updated text
    assert has_content?('Updated quote')
    assert_no_selector "div#editable_quote_#{quote.id}"
  end

  test 'editing a quote with empty fields shows validation errors inline' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    visit quotes_url

    # Create a quote to edit
    fill_in 'quote_quotation', with: 'Test quote'
    fill_in 'quote_source', with: 'Test source'
    click_button 'Save'
    assert has_content?('New quote created')

    quote = donpdonp.quotes.first

    # Click edit on the quote
    find('img.quote-edit-icon').click

    within "#editable_quote_#{quote.id}" do
      # Clear the quotation field and submit
      fill_in 'quote_quotation', with: ''
      click_button 'Save'
    end

    # Validation error should be displayed inline
    assert_selector 'p#quotation_error_msg', text: /can't be blank/

    # The form should still be visible (not reverted to display mode)
    assert_selector "div#editable_quote_#{quote.id}"

    # The rest of the page should still be intact (not replaced by just the edit form)
    assert has_content?('Add a New Quote')
    assert_selector 'input#quote_quotation'
  end

  test 'submitting the new quote form with empty fields shows validation errors' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    visit quotes_url
    assert_current_path quotes_path

    # Submit the form with empty fields
    click_button 'Save'

    # Validation errors should be displayed
    assert_selector 'p#quotation_error_msg', text: /can't be blank/
    assert_selector 'p#source_error_msg', text: /can't be blank/
  end
end
