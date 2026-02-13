require 'test_helper'

class TaskCategoryOperationsTest < ActionDispatch::IntegrationTest
  test 'CRUD operations on task categories from a logged-in user' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Ensure the Uncategorized task category exists
    assert_equal 'Uncategorized', donpdonp.task_categories.first.name

    # View task categories
    get task_categories_path
    assert_response :success
    assert_equal 1, donpdonp.task_categories.size
    assert_select 'p', 'You have no task categories to display.'

    # Create a new task category
    post task_categories_path, params: { task_category: { name: 'Ice Condor' } }
    assert_redirected_to task_categories_path
    assert_equal 'New task category created', flash[:success]
    assert_equal 2, donpdonp.task_categories.size

    first_tc = donpdonp.task_categories.find_by(name: 'Ice Condor')

    # Show the task category (turbo frame)
    get task_category_path(first_tc)
    assert_equal 'text/html', @response.media_type
    assert_match(/Ice Condor/, @response.body)

    # Show the editable task category (turbo frame)
    get edit_task_category_path(first_tc)
    assert_equal 'text/html', @response.media_type
    assert_match(/Ice Condor/, @response.body)

    # Update the task category
    patch task_category_path(first_tc),
          params: { task_category: { name: 'Everyone Delivers' } }
    assert_redirected_to task_categories_path
    assert_equal 'Task Category updated', flash[:success]
    first_tc.reload
    assert_equal 'Everyone Delivers', first_tc.name

    # Delete the task category
    delete task_category_path(first_tc)
    assert_redirected_to task_categories_path
    assert_equal 'Task Category deleted', flash[:success]
    get task_categories_path
    assert_equal 1, donpdonp.task_categories.size
    assert_select 'p', 'You have no task categories to display.'
  end

  test 'try to create invalid task categories' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    get task_categories_path

    # Empty task category name
    assert_no_difference 'donpdonp.task_categories.count' do
      post task_categories_path, params: { task_category: { name: '' } }
    end
    assert_template 'task_categories/index'
    assert_select 'p#name_error_msg', /can't be blank/

    # Empty task category name (whitespace)
    assert_no_difference 'donpdonp.task_categories.count' do
      post task_categories_path, params: { task_category: { name: '   ' } }
    end
    assert_template 'task_categories/index'
    assert_select 'p#name_error_msg', /can't be blank/

    # Too-long (51 char) task category name
    assert_no_difference 'donpdonp.task_categories.count' do
      post task_categories_path, params: { task_category: { name: 'a' * 51 } }
    end
    assert_template 'task_categories/index'
    assert_select 'p#name_error_msg', /is too long/
  end

  test 'try to update a task category with invalid data' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Create a task category first
    post task_categories_path, params: { task_category: { name: 'Work' } }
    tc = donpdonp.task_categories.find_by_name('Work')

    # Update with empty name
    patch task_category_path(tc), params: { task_category: { name: '' } }
    assert_response :unprocessable_entity
    assert_select 'p#name_error_msg', /can't be blank/

    # Update with too-long name
    patch task_category_path(tc), params: { task_category: { name: 'a' * 51 } }
    assert_response :unprocessable_entity
    assert_select 'p#name_error_msg', /is too long/

    # Verify task category was not changed
    tc.reload
    assert_equal 'Work', tc.name
  end

  test 'try to edit an invalid task category' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    get task_categories_path

    # Invalid task category id
    invalid_id = 3_928_104_982
    assert_raises 'ActiveRecord::RecordNotFound' do
      TaskCategory.find(invalid_id)
    end

    get edit_task_category_path(invalid_id), xhr: true
    patch task_category_path(invalid_id),
          params: { task_category: { name: 'Everyone Delivers' } }
    assert_redirected_to task_categories_path
    assert_equal 'Update failed: Task Category not found', flash[:danger]
  end

  test 'ensure deleting a task category reassigns all impacted tasks to the ' \
       'Uncategorized category' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates a task category
    log_in_as(donpdonp)

    get task_categories_path
    assert_response :success
    assert_equal 1, donpdonp.task_categories.size
    assert_select 'p', 'You have no task categories to display.'

    # Create a new task category
    post task_categories_path, params: { task_category: { name: 'Ice Condor' } }
    assert_redirected_to task_categories_path
    assert_equal 2, donpdonp.task_categories.size

    # Now create three tasks, using the Ice Condor task category
    uncategorized_tc = donpdonp.task_categories.find_by_name('Uncategorized')
    ice_condor_tc = donpdonp.task_categories.find_by_name('Ice Condor')
    assert_not_nil ice_condor_tc

    post tasks_path, params: { task: {
      summary: 'A first task',
      priority: '1',
      task_category_id: ice_condor_tc.id,
      due_at: Date.current.to_fs(:db)
    } }

    post tasks_path, params: { task: {
      summary: 'A second task',
      priority: '1',
      task_category_id: ice_condor_tc.id,
      due_at: Date.current.to_fs(:db)
    } }

    post tasks_path, params: { task: {
      summary: 'A third task',
      priority: '1',
      task_category_id: ice_condor_tc.id,
      due_at: Date.current.to_fs(:db)
    } }

    # Mark the third task is completed
    third_task = donpdonp.tasks.find_by_summary('A third task')
    assert_not_nil third_task
    post toggle_task_status_path(third_task.id), xhr: true
    third_task.reload
    assert_equal 'COMPLETED', third_task.status

    assert_equal 3, donpdonp.tasks.where('task_category_id = ?',
                                         ice_condor_tc.id).count

    # Delete the Ice Condor task category
    delete task_category_path(ice_condor_tc)

    assert_equal 0, donpdonp.tasks.where('task_category_id = ?',
                                         ice_condor_tc.id).count
    assert_equal 3, donpdonp.tasks.where('task_category_id = ?',
                                         uncategorized_tc.id).count
  end

  test 'ensure users cannot modify or delete their Uncategorized task ' \
       'category' do
    ows = users(:onewheelskyward)
    log_in_as(ows)

    get task_categories_path
    assert_response :success
    assert_equal 1, ows.task_categories.size
    uncategorized_tc = ows.task_categories.find_by_name('Uncategorized')
    assert_not_nil uncategorized_tc

    # Try to edit the Uncategorized task category
    patch task_category_path(uncategorized_tc),
          params: { task_category: { name: 'Bogus' } }
    assert_redirected_to task_categories_path
    assert_equal 'The Uncategorized task category cannot be renamed',
                 flash[:danger]
    uncategorized_tc.reload
    assert_equal 'Uncategorized', uncategorized_tc.name

    # Try to delete the Uncategorized task category
    delete task_category_path(uncategorized_tc)
    assert_equal 1, ows.task_categories.size
    uncategorized_tc = ows.task_categories.find_by_name('Uncategorized')
    assert_not_nil uncategorized_tc
  end

  test 'ensure users cannot edit or delete the task categories of other ' \
       'users' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp logs in and creates a task category
    log_in_as(donpdonp)

    get task_categories_path
    assert_response :success
    assert_equal 1, donpdonp.task_categories.size
    assert_select 'p', 'You have no task categories to display.'

    # Create a new task category
    post task_categories_path, params: { task_category: { name: 'Ice Condor' } }
    assert_redirected_to task_categories_path
    assert_equal 2, donpdonp.task_categories.size

    dons_tc = donpdonp.task_categories.find_by(name: 'Ice Condor')

    # onewheelskyward logs in and tries to show/edit/delete donpdonp's quote
    log_in_as(ows)

    get task_categories_path
    assert_response :success
    assert_equal 1, ows.task_categories.size
    assert_select 'p', 'You have no task categories to display.'

    # Show Don's task category
    get task_category_path(dons_tc)
    assert_redirected_to task_categories_path
    assert_equal 'Task Category not found', flash[:danger]

    # Edit Don's task category
    patch task_category_path(dons_tc),
          params: { task_category: { name: 'Bike Repair' } }
    assert_redirected_to task_categories_path
    assert_equal 'Update failed: Task Category not found', flash[:danger]
    dons_tc.reload
    assert_equal 'Ice Condor', dons_tc.name

    # Delete Don's task category
    delete task_category_path(dons_tc)
    assert_redirected_to task_categories_path
    assert_equal 'Deleting Task Category failed: category not found',
                 flash[:danger]
    get task_categories_path
    assert_equal 1, ows.task_categories.size
    assert_equal 2, donpdonp.task_categories.size
    assert_select 'p', 'You have no task categories to display.'
  end

  test 'delete_confirmation should display impacted task count' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Create a task category with no tasks
    post task_categories_path, params: { task_category: { name: 'Empty Category' } }
    empty_tc = donpdonp.task_categories.find_by_name('Empty Category')

    # Request delete confirmation for empty category (0 impacted tasks)
    get task_category_delete_with_confirmation_path(empty_tc),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', @response.media_type
    assert_match(/0 existing tasks in this category/, @response.body)
    assert_match(/Confirm Task Category Deletion/, @response.body)

    # Create another task category with tasks
    post task_categories_path, params: { task_category: { name: 'Busy Category' } }
    busy_tc = donpdonp.task_categories.find_by_name('Busy Category')

    # Create 3 tasks in this category
    3.times do |i|
      post tasks_path, params: { task: {
        summary: "Task #{i + 1}",
        priority: '1',
        task_category_id: busy_tc.id,
        due_at: Date.current.to_fs(:db)
      } }
    end

    # Request delete confirmation for busy category (3 impacted tasks)
    get task_category_delete_with_confirmation_path(busy_tc),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', @response.media_type
    assert_match(/3 existing tasks in this category/, @response.body)
    assert_match(/Confirm Task Category Deletion/, @response.body)
  end

  test 'delete_confirmation should fail for invalid task category' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Try to request delete confirmation for non-existent category
    invalid_id = 9_999_999
    get task_category_delete_with_confirmation_path(invalid_id),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_redirected_to task_categories_path
    assert_equal 'Deleting Task Category failed: category not found', flash[:danger]
  end

  test 'delete_confirmation should fail for another user\'s task category' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp creates a task category
    log_in_as(donpdonp)
    post task_categories_path, params: { task_category: { name: 'Don\'s Category' } }
    dons_tc = donpdonp.task_categories.find_by_name('Don\'s Category')

    # onewheelskyward tries to see delete confirmation for Don's category
    log_in_as(ows)
    get task_category_delete_with_confirmation_path(dons_tc),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_redirected_to task_categories_path
    assert_equal 'Deleting Task Category failed: category not found', flash[:danger]
  end

  # ── Progressive enhancement: HTML fallback tests ──

  test 'delete_confirmation renders a standalone HTML page without Turbo' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    post task_categories_path, params: { task_category: { name: 'HTML Test' } }
    tc = donpdonp.task_categories.find_by_name('HTML Test')

    # Request without turbo_stream Accept header — should render HTML page
    get task_category_delete_with_confirmation_path(tc)
    assert_response :success
    assert_equal 'text/html', @response.media_type
    assert_match(/Confirm Task Category Deletion/, @response.body)
    assert_match(/0 existing tasks in this category/, @response.body)
  end

  # ── Progressive enhancement: Turbo Stream response tests ──

  test 'update responds with turbo_stream when requested' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    post task_categories_path, params: { task_category: { name: 'Turbo Update' } }
    tc = donpdonp.task_categories.find_by_name('Turbo Update')

    patch task_category_path(tc),
          params: { task_category: { name: 'Turbo Updated' } },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', @response.media_type
    assert_match(/turbo-stream/, @response.body)
    assert_match(/Turbo Updated/, @response.body)

    tc.reload
    assert_equal 'Turbo Updated', tc.name
  end

  test 'destroy responds with turbo_stream when requested' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    post task_categories_path, params: { task_category: { name: 'Turbo Delete' } }
    tc = donpdonp.task_categories.find_by_name('Turbo Delete')
    tc_count = donpdonp.task_categories.count

    delete task_category_path(tc),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', @response.media_type
    assert_match(/turbo-stream.*action="remove"/, @response.body)
    assert_match(/Task Category deleted/, @response.body)
    assert_equal tc_count - 1, donpdonp.task_categories.reload.count
  end

  test 'destroy falls back to HTML redirect without Turbo' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    post task_categories_path, params: { task_category: { name: 'HTML Delete' } }
    tc = donpdonp.task_categories.find_by_name('HTML Delete')

    delete task_category_path(tc)
    assert_redirected_to task_categories_path
    assert_equal 'Task Category deleted', flash[:success]
  end
end
