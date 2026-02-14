require 'application_system_test_case'

class TaskSearchFeaturesTest < ApplicationSystemTestCase
  test 'ensure search results remain persistent when reloading the page' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    click_button 'Search Tasks'
    assert_selector('div.display-task-summary', count: 20)

    # Reload the current page and check that the results are the same
    page.driver.browser.navigate.refresh
    assert_selector('div.display-task-summary', count: 20)
  end

  test 'check that search result pagination is working correctly' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    click_button 'Search Tasks'
    assert_selector('div.display-task-summary', count: 20)

    # There should be 10 search results on the second page
    click_link '2'
    assert_selector('div.display-task-summary', count: 10)
  end

  test 'check that search result sorting options work correctly' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    choose 'tasks_filter_incomplete'
    click_button 'Search Tasks'
    assert_selector('div.display-task-summary', count: 11)
    # Confirm that the tasks do not appear in priority order to begin with
    assert_raises 'Capybara::ElementNotFound' do
      regex = /
        Aaronpk\stask26\spriority1
        .*
        Aaronpk\stask28\spriority1
        .*
        Aaronpk\stask29\spriority2
        .*
        Aaronpk\stask30
      /mx
      find('div#search_results_container', text: regex)
    end

    # Select 'Priority - Highest First', from: 'sort_by'
    # option[3] is Priority - Highest First
    find('#sort_by').find(:xpath, 'option[3]').select_option
    assert_selector('div.display-task-summary', count: 11)

    # Confirm the tasks are now appearing in priority order
    regex_priority_order = /
      Aaronpk\stask26\spriority1
      .*
      Aaronpk\stask28\spriority1
      .*
      Aaronpk\stask29\spriority2
      .*
      Aaronpk\stask30
    /mx
    assert find('div#search_results_container', text: regex_priority_order)

    # Change the sort method to Priority - Lowest First
    # option[4] is Priority - Lowest First
    find('#sort_by').find(:xpath, 'option[4]').select_option
    assert_selector('div.display-task-summary', count: 11)

    # Confirm the tasks are not appearing in priority order
    assert_raises 'Capybara::ElementNotFound' do
      regex = /
        Aaronpk\stask26\spriority1
        .*
        Aaronpk\stask28\spriority1
        .*
        Aaronpk\stask29\spriority2
        .*
        Aaronpk\stask30
      /mx
      find('div#search_results_container', text: regex)
    end

    # But instead are appearing in reverse priority order
    regex_reverse_priority_order = /
      Aaronpk\stask30
      .*
      Aaronpk\stask29\spriority2
      .*
      Aaronpk\stask26\spriority1
      .*
      Aaronpk\stask28\spriority1
    /mx
    assert find('div#search_results_container',
                text: regex_reverse_priority_order)
  end
end
