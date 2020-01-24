require 'test_helper'

class TaskOperationsTest < ActionDispatch::IntegrationTest
  # Assumes user is logged in already
  def create_task(user, due_at = nil, category = 'Uncategorized', priority = 1,
                  tag = 'generic', tasks_view = 'index', search_terms = nil)
    # Create a new task
    category_id = user.task_categories.find_by(name: category).id
    assert_difference 'user.tasks.count', 1 do
      post tasks_path(tasks_view: tasks_view, search_terms: search_terms),
           params: {
             task: {
               summary: "A #{tag} task",
               priority: priority,
               task_category_id: category_id,
               due_at: due_at
             }
           }
    end
  end

  test 'CRUD operations on tasks from a logged-in user' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View tasks
    get tasks_path
    assert_response :success
    assert_empty donpdonp.tasks
    assert_select 'p', 'There are no current tasks to display.'
    assert_select 'p', 'There are no completed tasks for today.'
    get upcoming_tasks_path
    assert_response :success
    assert_select 'p', 'There are no upcoming tasks to display.'

    # View tasks with no results (paginated messages)
    get tasks_path(page: 6)
    assert_response :success
    assert_select 'p', 'There are no current tasks to display for this page -' \
                       ' maybe try going back one page?'
    get upcoming_tasks_path(page: 6)
    assert_response :success
    assert_select 'p', 'There are no upcoming tasks to display for this page' \
                       ' - maybe try going back one page?'

    # Create a new task
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'A first task',
      priority: '1',
      task_category_id: uncategorized_id
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    first_task = donpdonp.tasks.first
    assert_equal first_task.summary, 'A first task'
    assert_equal first_task.priority, 1
    assert_equal first_task.task_category_id, uncategorized_id

    # Show the task (ajax)
    get task_path(first_task), xhr: true
    assert_equal 'text/javascript', @response.media_type
    assert_match(/A first task/, @response.body)

    # Show the editable task (ajax)
    get edit_task_path(first_task), xhr: true
    assert_equal 'text/javascript', @response.media_type
    assert_match(/A first task/, @response.body)

    # Update the task
    patch task_path(first_task), params: { task: {
      summary: 'First edited task',
      priority: '2'
    } }
    assert_redirected_to tasks_path
    assert_equal 'Task updated', flash[:success]
    first_task.reload
    assert_equal first_task.summary, 'First edited task'
    assert_equal first_task.priority, 2

    # Delete the task
    delete task_path(first_task)
    assert_redirected_to tasks_path
    assert_empty donpdonp.tasks
    get tasks_path
    assert_response :success
    assert_select 'p', 'There are no current tasks to display.'
  end

  test 'try to create invalid tasks' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id

    # Empty task name
    assert_no_difference 'donpdonp.tasks.size' do
      post tasks_path, params: { task: {
        summary: '',
        priority: '1',
        task_category_id: uncategorized_id,
        due_at: Date.tomorrow.to_s(:db)
      } }
    end
    assert_template 'tasks/index'
    assert_select 'p#summary_error_msg', /can't be blank/

    # Empty task name (whitespace)
    assert_no_difference 'donpdonp.tasks.size' do
      post tasks_path, params: { task: {
        summary: '   ',
        priority: '1',
        task_category_id: uncategorized_id,
        due_at: Date.tomorrow.to_s(:db)
      } }
    end
    assert_template 'tasks/index'
    assert_select 'p#summary_error_msg', /can't be blank/

    # Task summary too long
    assert_no_difference 'donpdonp.tasks.size' do
      post tasks_path, params: { task: {
        summary: 'a' * 151,
        priority: '1',
        task_category_id: uncategorized_id,
        due_at: Date.tomorrow.to_s(:db)
      } }
    end
    assert_template 'tasks/index'
    assert_select 'p#summary_error_msg', /is too long/
  end

  test 'try to edit an invalid task' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    get tasks_path

    # Invalid task id
    invalid_id = 3_928_104_982
    assert_raises 'ActiveRecord::RecordNotFound' do
      Task.find(invalid_id)
    end

    get edit_task_path(invalid_id), xhr: true
    patch task_path(invalid_id), params: { task:
                                           { name: 'This is an invalid task' } }
    assert_redirected_to tasks_path
    assert_equal 'Updating task failed: task not found', flash[:danger]
  end

  test 'basic task operations that use AJAX' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    create_task(donpdonp)
    assert_equal donpdonp.tasks.size, 1
    task = donpdonp.tasks.first
    assert_equal task.summary, 'A generic task'
    assert_equal task.status, 'INCOMPLETE'

    # Display a task via show (ajax)
    get task_path(task), xhr: true
    assert_response :success
    assert_equal 'text/javascript', @response.media_type
    assert_match(/A generic task/, @response.body)
  end

  test "toggle a tasks' completed status" do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    create_task(donpdonp)
    task = donpdonp.tasks.first
    assert_equal donpdonp.tasks.size, 1
    assert_equal task.summary, 'A generic task'
    assert_equal task.status, 'INCOMPLETE'

    # Mark the task completed
    post toggle_task_status_path(task.id), xhr: true
    task.reload
    assert_equal task.summary, 'A generic task'
    assert_equal task.status, 'COMPLETED'

    # Un-mark the task to make it incomplete again
    post toggle_task_status_path(task.id), xhr: true
    task.reload
    assert_equal task.summary, 'A generic task'
    assert_equal task.status, 'INCOMPLETE'
  end

  test 'create and display a future-dated task' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View tasks
    get tasks_path
    assert_response :success
    assert_empty donpdonp.tasks
    assert_select 'p', 'There are no current tasks to display.'
    assert_select 'p', 'There are no completed tasks for today.'

    get upcoming_tasks_path
    assert_response :success
    assert_select 'p', 'There are no upcoming tasks to display.'

    # Create a new task
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'A first task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Date.tomorrow.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    get tasks_path
    assert_response :success
    assert_select 'p', 'There are no current tasks to display.'
    assert_select 'p', 'There are no completed tasks for today.'
    assert_select 'p', count: 0, text: 'There are no upcoming tasks to' \
                                         ' display.'
  end

  test 'create a task and mark it as completed' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View tasks
    get tasks_path
    assert_response :success
    assert_empty donpdonp.tasks
    assert_select 'p', 'There are no current tasks to display.'
    assert_select 'p', 'There are no completed tasks for today.'
    get upcoming_tasks_path
    assert_response :success
    assert_select 'p', 'There are no upcoming tasks to display.'

    create_task(donpdonp)
    assert_equal donpdonp.tasks.size, 1
    first_task = donpdonp.tasks.first
    assert_equal first_task.status, 'INCOMPLETE'
    assert_nil first_task.completed_at

    # Mark the task as completed
    post toggle_task_status_path(first_task), xhr: true
    first_task.reload
    assert_equal first_task.status, 'COMPLETED'
    assert_not_nil first_task.completed_at

    get tasks_path
    assert_response :success
    assert_select 'p', 'There are no current tasks to display.'
    assert_select 'p', count: 0, text: 'There are no completed tasks for' \
                                         ' today.'
    get upcoming_tasks_path
    assert_response :success
    assert_select 'p', 'There are no upcoming tasks to display.'
  end

  test 'ensure filtering tasks by task category works correctly' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)
    assert_equal 30, aaronpk.tasks.count

    get tasks_path
    assert_response :success
    assert_select 'div.display-task-summary', 9

    get tasks_path(category: 'Work')
    assert_response :success
    assert_select 'div.display-task-summary', 1

    get upcoming_tasks_path
    assert_response :success
    assert_select 'div.display-task-summary', 2

    get upcoming_tasks_path(category: 'Work')
    assert_response :success
    assert_select 'div.display-task-summary', 1
  end

  test 'ensure current and future tasks are sorted by due date' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates several tasks
    log_in_as(donpdonp)

    tz = donpdonp.time_zone
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'First task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.advance(days: 3).to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    post tasks_path, params: { task: {
      summary: 'Second task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.tomorrow.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 2

    post tasks_path, params: { task: {
      summary: 'Third task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 3

    post tasks_path, params: { task: {
      summary: 'Fourth task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.yesterday.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 4

    # If the tasks are being sorted by due date, they should appear
    # in the following order: Fourth, Third, Second, First
    get tasks_path
    assert_match(/.*Fourth task.*Third task.*/m, response.body)

    get upcoming_tasks_path
    assert_match(/.*Second task.*First task.*/m, response.body)
  end

  test 'ensure current and future tasks with the same due date are sorted by' \
       ' priority' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    assert_equal donpdonp.tasks.count, 0

    # donpdonp creates three tasks with no due date
    create_task(donpdonp, nil, 'Uncategorized', 2, 'priority2', 'index', nil)
    create_task(donpdonp, nil, 'Uncategorized', 1, 'priority1', 'index', nil)
    create_task(donpdonp, nil, 'Uncategorized', 3, 'priority3', 'index', nil)
    assert_equal 3, donpdonp.tasks.count

    # Proper sorting of task priorities should result in them appearing in the
    # order: priority1, priority2, priority3
    get tasks_path
    assert_response :success
    regex = /
      A\spriority1\stask
      .*
      A\spriority2\stask
      .*
      A\spriority3\stask
    /mx
    assert_match(regex, response.body)

    # delete the three tasks
    3.times do
      task = donpdonp.tasks.first
      delete task_path(task)
    end
    assert_equal 0, donpdonp.tasks.count

    # now he creates three tasks with a due date of today
    today_db = Time.now.in_time_zone(donpdonp.time_zone).to_date.to_s(:db)
    create_task(donpdonp, today_db, 'Uncategorized', 2, 'priority2',
                'index', nil)
    create_task(donpdonp, today_db, 'Uncategorized', 1, 'priority1',
                'index', nil)
    create_task(donpdonp, today_db, 'Uncategorized', 3, 'priority3',
                'index', nil)
    assert_equal 3, donpdonp.tasks.count
    assert_equal 3, donpdonp.tasks.current(today_db).count

    # Proper sorting of task priorities should result in them appearing in the
    # order: priority1, priority2, priority3
    get tasks_path
    assert_response :success
    regex = /
      A\spriority1\stask
      .*
      A\spriority2\stask
      .*
      A\spriority3\stask
    /mx
    assert_match(regex, response.body)

    # now he creates three tasks with a due date of tomorrow
    tomorrow_db = Time.now.in_time_zone(donpdonp.time_zone).to_date
                      .advance(days: 1).to_s(:db)
    create_task(donpdonp, tomorrow_db, 'Uncategorized', 2, 'priority2',
                'index', nil)
    create_task(donpdonp, tomorrow_db, 'Uncategorized', 1, 'priority1',
                'index', nil)
    create_task(donpdonp, tomorrow_db, 'Uncategorized', 3, 'priority3',
                'index', nil)
    assert_equal 6, donpdonp.tasks.count
    assert_equal 3, donpdonp.tasks.future(today_db).count

    # Proper sorting of task priorities should result in them appearing in the
    # order: priority1, priority2, priority3
    get upcoming_tasks_path
    assert_response :success
    regex = /
      A\spriority1\stask
      .*
      A\spriority2\stask
      .*
      A\spriority3\stask
    /mx
    assert_match(regex, response.body)
  end

  test 'ensure the auto-update overdue tasks button works' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates an overdue task
    log_in_as(donpdonp)

    get tasks_path
    assert_select 'div#advance_overdue_tasks_button_container', false

    tz = donpdonp.time_zone
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'An overdue task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: 5.days.ago.to_date.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    overdue_task = donpdonp.tasks.first
    assert_equal overdue_task.summary, 'An overdue task'

    get tasks_path
    assert_select 'div#advance_overdue_tasks_button_container'

    # he presses the Auto-Update Overdue Tasks button
    post advance_overdue_tasks_path
    assert_redirected_to tasks_path
    get tasks_path
    assert_select 'div.alert-flex-container', 'Updated 1 task due date to today'

    overdue_task.reload
    assert_equal overdue_task.due_at, Time.now.in_time_zone(tz).to_date

    # ensure that pressing the button again is idempotent
    post advance_overdue_tasks_path

    overdue_task.reload
    assert_equal overdue_task.due_at, Time.now.in_time_zone(tz).to_date

    get tasks_path
    assert_select 'div#advance_overdue_tasks_button_container', false
  end

  test 'ensure that after creating a new task, any selected task category' \
       ' filter is remembered and the correct task view tab is displayed' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates some new tasks
    log_in_as(donpdonp)

    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path(category: 'Uncategorized'), params: { task: {
      summary: 'First task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.to_date.to_s(:db)
    } }
    assert_redirected_to tasks_path(category: 'Uncategorized')

    post tasks_path(tasks_view: 'upcoming', category: 'Uncategorized'),
         params: { task:
                   { summary: 'Second task',
                     priority: '1',
                     task_category_id: uncategorized_id,
                     due_at: Time.now.to_date.to_s(:db) } }
    assert_redirected_to upcoming_tasks_path(category: 'Uncategorized')

    get search_tasks_path(tasks_view: 'search', category: 'Uncategorized'),
        params: { task:
                  { summary: 'Third task',
                    priority: '1',
                    task_category_id: uncategorized_id,
                    due_at: Time.now.to_date.to_s(:db) } }
    assert_response :success
  end

  test 'ensure that search parameters are preserved after performing task' \
       ' operations from the search tab' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates a new task
    log_in_as(donpdonp)

    create_task(donpdonp)
    assert_equal donpdonp.tasks.size, 1

    # He performs a search, which should display one result
    get search_tasks_path(search_terms: 'generic', tasks_filter: 'all',
                          task_category_filter: 'All')
    assert_response :success
    assert_select 'div.alert-flex-container', 'New task created'
    assert_select 'div.display-task-summary', 'A generic task'

    # Creating a new task from the search view should result in the same
    # search parameters being preserved after redirect.
    create_task(donpdonp, nil, 'Uncategorized', 1, 'generic', 'search',
                'generic')
    assert_equal donpdonp.tasks.size, 2
    assert_redirected_to search_tasks_path(search_terms: 'generic')
    get search_tasks_path
    assert_select 'div.alert-flex-container', "New task created (in Today's" \
                                              ' Tasks list)'
  end

  test 'ensure that updating and deleting an upcoming task redirects to the' \
       ' upcoming tasks tab' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates a future-dated task
    log_in_as(donpdonp)

    tz = donpdonp.time_zone
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'First task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.advance(days: 3).to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    # Edit the task
    first_task = donpdonp.tasks.first
    patch task_path(first_task, tasks_view: 'upcoming'), params: { task: {
      summary: 'First edited task',
      priority: '2'
    } }
    assert_redirected_to upcoming_tasks_path

    # Delete the task
    delete task_path(first_task, tasks_view: 'upcoming')
    assert_redirected_to upcoming_tasks_path
  end

  test 'ensure that updating and deleting a task while filtered by task' \
       ' category redirects to the same task category filter' do
    donpdonp = users(:donpdonp)

    # donpdonp logs in and creates a current task
    log_in_as(donpdonp)

    tz = donpdonp.time_zone
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    post tasks_path, params: { task: {
      summary: 'First task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    # Edit the task while using the Uncategorized task filter
    first_task = donpdonp.tasks.first
    patch task_path(first_task, category: 'Uncategorized'), params: { task: {
      summary: 'First edited task',
      priority: '2'
    } }
    assert_redirected_to tasks_path(category: 'Uncategorized')

    # Delete the task while using the Uncategorized task filter
    delete task_path(first_task, category: 'Uncategorized')
    assert_redirected_to tasks_path(category: 'Uncategorized')

    # Now donpdonp does the same for an upcoming task
    post tasks_path, params: { task: {
      summary: 'First task',
      priority: '1',
      task_category_id: uncategorized_id,
      due_at: Time.now.in_time_zone(tz).to_date.advance(days: 3).to_s(:db)
    } }
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.size, 1

    # Edit the task while using the Uncategorized task filter
    first_task = donpdonp.tasks.first
    patch task_path(first_task, tasks_view: 'upcoming',
                                category: 'Uncategorized'),
          params: { task: { summary: 'First edited task', priority: '2' } }
    assert_redirected_to upcoming_tasks_path(category: 'Uncategorized')

    # Delete the task while using the Uncategorized task filter
    delete task_path(first_task, tasks_view: 'upcoming',
                                 category: 'Uncategorized')
    assert_redirected_to upcoming_tasks_path(category: 'Uncategorized')
  end

  test 'check the flash messages when tasks are created and updated from' \
       ' various task views' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Current task creation from Today's Tasks view
    create_task(donpdonp)
    assert_equal donpdonp.tasks.size, 1
    get tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', 'New task created'

    # Current task creation from Upcoming Tasks view
    create_task(donpdonp, nil, 'Uncategorized', 1, 'generic', 'upcoming')
    assert_equal donpdonp.tasks.size, 2
    get upcoming_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', "New task created (in Today's" \
                                              ' Tasks list)'

    # Current task creation from Search view
    create_task(donpdonp, nil, 'Uncategorized', 1, 'generic', 'search')
    assert_equal donpdonp.tasks.size, 3
    get search_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', "New task created (in Today's" \
                                              ' Tasks list)'

    # Current task update from Today's Tasks view
    current_task = donpdonp.tasks.first
    patch task_path(current_task), params: { task: {
      summary: 'First edited generic task'
    }, tasks_view: 'index' }
    assert_redirected_to tasks_path
    get tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', 'Task updated'

    # Current task update from Upcoming Tasks view
    patch task_path(current_task), params: { task: {
      summary: 'Twice edited generic task'
    }, tasks_view: 'upcoming' }
    assert_redirected_to upcoming_tasks_path
    get upcoming_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', "Task updated (in Today's" \
                                              ' Tasks list)'

    # Current task update from Search view
    patch task_path(current_task), params: { task: {
      summary: 'Thrice edited generic task'
    }, tasks_view: 'search' }
    assert_redirected_to search_tasks_path
    get search_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', "Task updated (in Today's" \
                                              ' Tasks list)'

    task1, task2, task3 = donpdonp.tasks[0..2]
    assert_not task1.nil?
    assert_not task2.nil?
    assert_not task3.nil?

    # Delete task from Today's Tasks view
    delete task_path(task1, tasks_view: 'index')
    assert_redirected_to tasks_path
    get tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', 'Task deleted'

    # Delete task from Upcoming Tasks view
    delete task_path(task2, tasks_view: 'upcoming')
    assert_redirected_to upcoming_tasks_path
    get upcoming_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', 'Task deleted'

    # Delete task from Search Tasks view
    delete task_path(task3, tasks_view: 'search')
    assert_redirected_to search_tasks_path
    get search_tasks_path
    assert_response :success
    assert_select 'div.alert-flex-container', 'Task deleted'
  end

  test 'ensure users cannot edit, modify, or delete the quotes of other' \
       ' users' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp logs in and creates a task
    log_in_as(donpdonp)

    create_task(donpdonp)
    assert_equal donpdonp.tasks.size, 1
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    dons_task = donpdonp.tasks.first
    assert_equal dons_task.summary, 'A generic task'
    assert_equal dons_task.priority, 1
    assert_equal dons_task.task_category_id, uncategorized_id

    # onewheelskyward logs in and tries to show/edit/modify/delete donpdonp's
    # task
    log_in_as(ows)

    get tasks_path
    assert_response :success
    assert_empty ows.tasks
    assert_select 'p', 'There are no current tasks to display.'

    # Show Don's task
    get task_path(dons_task)
    assert_redirected_to tasks_path

    # Edit Don's task
    patch task_path(dons_task), params: { task: {
      summary: 'First edited task',
      priority: '2'
    } }
    assert_redirected_to tasks_path
    dons_task.reload
    assert_equal dons_task.summary, 'A generic task'
    assert_equal dons_task.priority, 1

    # Mark Don's task as complete
    assert_equal dons_task.status, 'INCOMPLETE'
    post toggle_task_status_path(dons_task), xhr: true
    dons_task.reload
    assert_equal dons_task.status, 'INCOMPLETE'

    # Delete Don's task
    delete task_path(dons_task)
    assert_redirected_to tasks_path
    assert_equal donpdonp.tasks.reload.size, 1
  end

  test 'display_quotes should toggle the display of quotes on the tasks' \
       ' index' do
    don = users(:donpdonp)
    log_in_as(don)

    get tasks_url
    assert_response :success
    assert_template 'tasks/index'

    # display_quotes defaults to true, so quotes should be visible
    assert don.setting.display_quotes
    assert_select 'div#header_quote_container'

    don.setting.display_quotes = false
    don.setting.save
    get tasks_url
    assert_response :success
    assert_template 'tasks/index'
    assert_select 'div#header_quote_container', 0
  end

  test 'ensure that free plan users get the correct 5 awwyiss modals' do
    # leofsiege is a free plan user
    leofsiege = users(:leofsiege)
    log_in_as(leofsiege)

    valid_modals = %w[awwyiss_modal_bravocado
                      awwyiss_modal_hell_yes
                      awwyiss_modal_like_a_boss
                      awwyiss_modal_nice_one
                      awwyiss_modal_unstoppable2]

    # Reload the page 20 times to get a good sampling of results
    20.times do
      get tasks_path
      assert_response :success
      awwyiss_modal = assigns(:awwyiss_modal)
      assert valid_modals.include?(awwyiss_modal)
    end
  end

  test 'ensure that pro plan users get the correct 12 awwyiss modals' do
    # donpdonp is a pro plan user
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    valid_modals = %w[awwyiss_modal_beavis_butthead1
                      awwyiss_modal_boom
                      awwyiss_modal_bravocado
                      awwyiss_modal_hell_yes
                      awwyiss_modal_like_a_boss
                      awwyiss_modal_nice_one
                      awwyiss_modal_oh_yeah
                      awwyiss_modal_unstoppable1
                      awwyiss_modal_unstoppable2
                      awwyiss_modal_victory]

    # Reload the page 30 times to get a good sampling of results
    30.times do
      get tasks_path
      assert_response :success
      awwyiss_modal = assigns(:awwyiss_modal)
      assert valid_modals.include?(awwyiss_modal)
    end
  end

  test 'ensure that premier plan users get the correct 20 awwyiss modals' do
    # onewheelskyward is a premier plan user
    onewheelskyward = users(:onewheelskyward)
    log_in_as(onewheelskyward)

    valid_modals = %w[awwyiss_modal_beavis_butthead1
                      awwyiss_modal_boom
                      awwyiss_modal_bravocado
                      awwyiss_modal_hell_yes
                      awwyiss_modal_like_a_boss
                      awwyiss_modal_nice_one
                      awwyiss_modal_oh_yeah
                      awwyiss_modal_unstoppable1
                      awwyiss_modal_unstoppable2
                      awwyiss_modal_victory]

    # Reload the page 30 times to get a good sampling of results
    30.times do
      get tasks_path
      assert_response :success
      awwyiss_modal = assigns(:awwyiss_modal)
      assert valid_modals.include?(awwyiss_modal)
    end
  end

  # Previously this crash bug happened in production
  test 'ensure that attemping to create an invalid task when quote history' \
       " is being saved doesn't cause a site crash" do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Create three quotes
    3.times do
      post quotes_path, params: { quote: { quotation: 'Quotation',
                                           source: 'Source' } }
    end
    assert_equal donpdonp.quotes.size, 3

    # Try to create a task with no summary
    uncategorized_id = donpdonp.task_categories.find_by(name: 'Uncategorized')
                               .id
    assert_no_difference 'donpdonp.tasks.size' do
      post tasks_path, params: { task: {
        summary: '',
        priority: '1',
        task_category_id: uncategorized_id,
        due_at: Date.today.to_s(:db)
      } }
    end
    assert_template 'tasks/index'
    assert_select 'p#summary_error_msg', /can't be blank/
  end
end
