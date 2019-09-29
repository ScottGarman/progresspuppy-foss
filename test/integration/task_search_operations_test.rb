require 'test_helper'

class TaskSearchOperationsTest < ActionDispatch::IntegrationTest
  test 'basic search operations' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    assert_equal 30, aaronpk.tasks.count
    tc_work = aaronpk.task_categories.find_by_name('Work')
    assert_not_nil tc_work

    # All of aaronpk's tasks contain the string 'aaronpk', so searching for this
    # string should return 30 tasks (paginated by 20)
    get search_tasks_path
    assert_response :success

    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'all',
                                     task_category_filter: 'All' }
    assert_response :success
    assert_select 'div.display-task-summary', 20
    assert_select 'div.display-task-summary', /Aaronpk task/

    # If we restrict the search to completed tasks, there should only be 19
    # results
    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'completed',
                                     task_category_filter: 'All' }
    assert_response :success
    assert_select 'div.display-task-summary', 19
    assert_select 'div.display-task-summary', /Aaronpk task/

    # If we restrict the search to incomplete tasks, there should only be 11
    # results
    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'incomplete',
                                     task_category_filter: 'All' }
    assert_response :success
    assert_select 'div.display-task-summary', 11
    assert_select 'div.display-task-summary', /Aaronpk task/

    # If we restrict the search to Work category tasks, there should be only 3
    # results
    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'all',
                                     task_category_filter: tc_work.id }
    assert_response :success
    assert_select 'div.display-task-summary', 3
    assert_select 'div.display-task-summary', /Aaronpk task/

    # If we restrict the search to incomplete Work category tasks, there should
    # be only 2 results
    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'incomplete',
                                     task_category_filter: tc_work.id }
    assert_response :success
    assert_select 'div.display-task-summary', 2
    assert_select 'div.display-task-summary', /Aaronpk task/

    # If we restrict the search to completed Work category tasks, there should
    # be only 1 result
    get search_tasks_path, params: { search_terms: 'aaronpk',
                                     tasks_filter: 'completed',
                                     task_category_filter: tc_work.id }
    assert_response :success
    assert_select 'div.display-task-summary', 1
    assert_select 'div.display-task-summary', /Aaronpk task/
  end
end
