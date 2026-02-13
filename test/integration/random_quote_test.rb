require 'test_helper'

class RandomQuoteTest < ActionDispatch::IntegrationTest
  # agj is the user who like testing quote-related features
  test 'ensure displayed quotes do not repeat the last 3 that were displayed' do
    # agj logs in
    agj = users(:agj)
    log_in_as(agj)

    assert agj.quotes.count, 5
    agj_recent_quotes = []

    # Reload the tasks page three times to enable quote history checking
    3.times do
      get tasks_path
      assert_response :success
      assert_select 'blockquote#header_quotation', 1
      quote = assigns(:quote)
      agj_recent_quotes << quote.id
    end

    # From now on, the next quote should not be found in the list of recent
    # quotes. We'll run this 25 times to exercise things thoroughly.
    25.times do
      get tasks_path
      assert_response :success
      assert_select 'blockquote#header_quotation', 1
      quote = assigns(:quote)
      assert_not agj_recent_quotes.include?(quote.id)
      agj_recent_quotes.shift
      agj_recent_quotes << quote.id
    end
  end
end
