require 'application_system_test_case'

class TaskSearchFeaturesTest < ApplicationSystemTestCase
  test 'ensure search results remain persistent when reloading the page' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    page.assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    click_button 'Search Tasks'
    page.assert_selector('div.display-task-summary', count: 20)

    # Reload the current page and check that the results are the same
    page.driver.browser.navigate.refresh
    page.assert_selector('div.display-task-summary', count: 20)
  end

  test 'check that search result pagination is working correctly' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    page.assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    click_button 'Search Tasks'
    page.assert_selector('div.display-task-summary', count: 20)

    # There should be 10 search results on the second page
    click_link '2'
    page.assert_selector('div.display-task-summary', count: 10)
  end

  test 'check that search result sorting options work correctly' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    visit search_tasks_url
    assert_current_path search_tasks_path
    page.assert_no_selector('div.display-task-summary')

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    fill_in 'search_terms', with: 'aaronpk'
    choose 'tasks_filter_incomplete'
    click_button 'Search Tasks'
    page.assert_selector('div.display-task-summary', count: 11)
    # Confirm that the tasks do not appear in priority order to begin with
    assert_raises 'Capybara::ElementNotFound' do
      page.find('div#search_results_container',
                text: /Aaronpk task26 priority1.*Aaronpk task28 priority1.*Aaronpk task29 priority2.*Aaronpk task30/m)
    end

    #select 'Priority - Highest First', from: 'sort_by'
    # option[3] is Priority - Highest First
    find('#sort_by').find(:xpath, 'option[3]').select_option
    page.assert_selector('div.display-task-summary', count: 11)

    # Confirm the tasks are now appearing in priority order
    assert page.find('div#search_results_container',
                     text: /Aaronpk task26 priority1.*Aaronpk task28 priority1.*Aaronpk task29 priority2.*Aaronpk task30/m)

    # Change the sort method to Priority - Lowest First
    # option[4] is Priority - Lowest First
    find('#sort_by').find(:xpath, 'option[4]').select_option
    page.assert_selector('div.display-task-summary', count: 11)

    # Confirm the tasks are not appearing in priority order
    assert_raises 'Capybara::ElementNotFound' do
      page.find('div#search_results_container',
                text: /Aaronpk task26 priority1.*Aaronpk task28 priority1.*Aaronpk task29 priority2.*Aaronpk task30/m)
    end

    # But instead are appearing in reverse priority order
    assert page.find('div#search_results_container',
                     text: /Aaronpk task30.*Aaronpk task29 priority2.*Aaronpk task26 priority1.*Aaronpk task28 priority1/m)
  end
end
