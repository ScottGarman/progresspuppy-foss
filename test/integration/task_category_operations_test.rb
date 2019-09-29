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

    # Show the task category (ajax)
    get task_category_path(first_tc), xhr: true
    assert_equal 'text/javascript', @response.media_type
    assert_match(/Ice Condor/, @response.body)

    # Show the editable task category (ajax)
    get edit_task_category_path(first_tc), xhr: true
    assert_equal 'text/javascript', @response.media_type
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

  test 'ensure deleting a task category reassigns all impacted tasks to the' \
       ' Uncategorized category' do
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
      due_at: Date.today.to_s(:db)
    } }

    post tasks_path, params: { task: {
      summary: 'A second task',
      priority: '1',
      task_category_id: ice_condor_tc.id,
      due_at: Date.today.to_s(:db)
    } }

    post tasks_path, params: { task: {
      summary: 'A third task',
      priority: '1',
      task_category_id: ice_condor_tc.id,
      due_at: Date.today.to_s(:db)
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

  test 'ensure users cannot modify or delete their Uncategorized task' \
       ' category' do
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

  test 'ensure users cannot edit or delete the task categories of other' \
       ' users' do
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
end
