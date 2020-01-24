require 'test_helper'

class QuoteOperationsTest < ActionDispatch::IntegrationTest
  test 'Check that the help tip quote is shown when no quotes are defined' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)
    assert_empty donpdonp.quotes

    get tasks_path
    assert_response :success
    assert_select 'div#header_quote_container'
    assert_select 'blockquote#header_quotation',
                  /To add custom quotes to appear here/
    assert_select 'blockquote#header_quotation',
                  /or disable the display of quotes altogether/
    assert_select 'footer#header_quotation_source', '-ProgressPuppy'

    get upcoming_tasks_path
    assert_response :success
    assert_select 'div#header_quote_container'
    assert_select 'blockquote#header_quotation',
                  /To add custom quotes to appear here/
    assert_select 'blockquote#header_quotation',
                  /or disable the display of quotes altogether/
    assert_select 'footer#header_quotation_source', '-ProgressPuppy'

    get search_tasks_path
    assert_response :success
    assert_select 'div#header_quote_container'
    assert_select 'blockquote#header_quotation',
                  /To add custom quotes to appear here/
    assert_select 'blockquote#header_quotation',
                  /or disable the display of quotes altogether/
    assert_select 'footer#header_quotation_source', '-ProgressPuppy'
  end

  test 'CRUD operations on quotes from a logged-in user' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View quotes
    get quotes_path
    assert_response :success
    assert_empty donpdonp.quotes
    assert_select 'p', 'Your list of quotes is currently empty.'

    # Create a new quote
    post quotes_path, params: { quote: { quotation: 'First new quote',
                                         source: 'Source One' } }
    assert_redirected_to quotes_path
    assert_equal 'New quote created', flash[:success]
    assert_equal donpdonp.quotes.size, 1

    first_quote = donpdonp.quotes.first
    assert_equal first_quote.quotation, 'First new quote'
    assert_equal first_quote.source, 'Source One'

    # Show the quote (ajax)
    get quote_path(first_quote), xhr: true
    assert_equal 'text/javascript', @response.media_type
    assert_match(/First new quote/, @response.body)

    # Show the editable quote (ajax)
    get edit_quote_path(first_quote), xhr: true
    assert_equal 'text/javascript', @response.media_type
    assert_match(/First new quote/, @response.body)

    # Update the quote
    patch quote_path(first_quote), params: { quote:
                                               { quotation: 'First edited' \
                                                            ' new quote',
                                                 source: 'Source One Edited' } }
    assert_redirected_to quotes_path
    assert_equal 'Quote updated', flash[:success]
    first_quote.reload
    assert_equal first_quote.quotation, 'First edited new quote'
    assert_equal first_quote.source, 'Source One Edited'

    # Delete the quote
    delete quote_path(first_quote)
    assert_redirected_to quotes_path
    assert_equal 'Quote deleted', flash[:success]
    assert_empty donpdonp.quotes
    get quotes_path
    assert_response :success
    assert_select 'p', 'Your list of quotes is currently empty.'
  end

  test 'try to create invalid quotes' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    get quotes_path

    # Empty quotation
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { quotation: '' } }
    end
    assert_template 'quotes/index'
    assert_select 'p#quotation_error_msg', /can't be blank/

    # Empty source
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { source: '' } }
    end
    assert_template 'quotes/index'
    assert_select 'p#source_error_msg', /can't be blank/

    # Empty quotation (whitespace)
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { quotation: '   ' } }
    end
    assert_template 'quotes/index'
    assert_select 'p#quotation_error_msg', /can't be blank/

    # Empty source (whitespace)
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { source: '   ' } }
    end
    assert_template 'quotes/index'
    assert_select 'p#source_error_msg', /can't be blank/

    # Too-long (256 char) quotation
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { quotation: 'a' * 256 } }
    end
    assert_template 'quotes/index'
    assert_select 'p#quotation_error_msg', /is too long/

    # Too-long (256 char) source
    assert_no_difference 'donpdonp.quotes.count' do
      post quotes_path, params: { quote: { source: 'a' * 256 } }
    end
    assert_template 'quotes/index'
    assert_select 'p#source_error_msg', /is too long/
  end

  test 'try to edit an invalid quote' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    get quotes_path

    # Invalid quote id
    invalid_id = 3_928_104_982
    assert_raises 'ActiveRecord::RecordNotFound' do
      Quote.find(invalid_id)
    end

    get edit_quote_path(invalid_id), xhr: true
    patch quote_path(invalid_id), params: { quote:
                                              { quotation: 'Editing an' \
                                                           ' invalid quote',
                                                source: 'Quotation Source' } }
    assert_redirected_to quotes_path
    assert_equal 'Updating quote failed: quote not found', flash[:danger]
  end

  test 'ensure users cannot edit or delete the quotes of other users' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp logs in and creates a quote
    log_in_as(donpdonp)

    get quotes_path
    assert_response :success
    assert_empty donpdonp.quotes
    assert_select 'p', 'Your list of quotes is currently empty.'

    # Create a new quote
    post quotes_path, params: { quote:
                                  { quotation: 'First new quote',
                                    source: 'Source One' } }
    assert_redirected_to quotes_path
    assert_equal donpdonp.quotes.size, 1

    dons_quote = donpdonp.quotes.first
    assert_equal dons_quote.quotation, 'First new quote'
    assert_equal dons_quote.source, 'Source One'

    # onewheelskyward logs in and tries to show/edit/delete donpdonp's quote
    log_in_as(ows)

    get quotes_path
    assert_response :success
    assert_empty ows.quotes
    assert_select 'p', 'Your list of quotes is currently empty.'

    # Show Don's quote
    get quote_path(dons_quote)
    assert_redirected_to quotes_path
    assert_equal 'Show quote failed: quote not found', flash[:danger]

    # Edit Don's quote
    patch quote_path(dons_quote), params: { quote:
                                              { quotation: 'First edited new' \
                                                           ' quote',
                                                source: 'Source One Edited' } }
    assert_redirected_to quotes_path
    assert_equal 'Updating quote failed: quote not found', flash[:danger]
    dons_quote.reload
    assert_equal dons_quote.quotation, 'First new quote'
    assert_equal dons_quote.source, 'Source One'

    # Delete Don's quote
    delete quote_path(dons_quote)
    assert_redirected_to quotes_path
    assert_equal 'Deleting quote failed: quote not found', flash[:danger]
    assert_equal donpdonp.quotes.size, 1
  end

  test 'verify the display of random quotes on the main task view' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Create three new quotes
    post quotes_path, params: { quote:
      { quotation: 'First quote', source: 'Source One' } }
    assert_redirected_to quotes_path
    assert_equal 'New quote created', flash[:success]
    assert_equal donpdonp.quotes.size, 1

    post quotes_path, params: { quote:
      { quotation: 'Second quote', source: 'Source Two' } }
    assert_redirected_to quotes_path
    assert_equal 'New quote created', flash[:success]
    assert_equal donpdonp.quotes.size, 2

    post quotes_path, params: { quote:
      { quotation: 'Third quote', source: 'Source Three' } }
    assert_redirected_to quotes_path
    assert_equal 'New quote created', flash[:success]
    assert_equal donpdonp.quotes.size, 3

    first_quote, second_quote, third_quote = donpdonp.quotes.sort_by(&:id)
    assert_equal first_quote.quotation, 'First quote'
    assert_equal first_quote.source, 'Source One'

    assert_equal second_quote.quotation, 'Second quote'
    assert_equal second_quote.source, 'Source Two'

    assert_equal third_quote.quotation, 'Third quote'
    assert_equal third_quote.source, 'Source Three'

    # Since the quotes are displayed randomly, reload the task view 20
    # times to ensure all three quotes are displayed.
    displayed_quotes = {}
    20.times do
      get tasks_path
      assert_response :success
      if @response.body =~ /First quote/
        displayed_quotes['First'] = true
      elsif @response.body =~ /Second quote/
        displayed_quotes['Second'] = true
      elsif @response.body =~ /Third quote/
        displayed_quotes['Third'] = true
      end
    end
    assert_equal 3, displayed_quotes.size
  end
end
