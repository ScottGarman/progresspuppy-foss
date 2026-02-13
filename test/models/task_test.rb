require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  def setup
    @user = User.new(first_name: 'Bubba',
                     last_name: 'Jones',
                     email: 'bubbajones@examples.com',
                     password: 'foobarbaz123',
                     password_confirmation: 'foobarbaz123',
                     accepted_tos: true)
    @user.save!
    @tc_work = TaskCategory.new(name: 'Work')
    @user.task_categories << @tc_work
    @tc_work.save!
    @user.save!
    @task = Task.new(summary: 'A first task',
                     task_category_id: @tc_work.id,
                     priority: 3,
                     status: 'INCOMPLETE')
  end

  test 'should be valid' do
    @user.tasks << @task
    assert @task.valid?
  end

  test 'a Task must be associated with a User' do
    assert @task.invalid?
    assert @task.errors[:user_id].any?
  end

  test 'summary should be present and not empty' do
    @user.tasks << @task
    @task.summary = '  '
    assert @task.invalid?
    assert @task.errors[:summary].any?
  end

  test 'summary should not be too long' do
    @user.tasks << @task
    @task.summary = 'a' * 151
    assert @task.invalid?
    assert @task.errors[:summary].any?

    @task.summary = 'a' * 150
    assert @task.valid?
  end

  test 'priority must be an integer from 1..3' do
    @task.priority = nil
    assert @task.invalid?
    assert @task.errors[:priority].any?

    @task.priority = 0
    assert @task.invalid?
    assert @task.errors[:priority].any?

    @task.priority = 4
    assert @task.invalid?
    assert @task.errors[:priority].any?

    @task.priority = 1
    @user.tasks << @task
    assert @task.valid?
  end

  test 'status must be either INCOMPLETE or COMPLETED' do
    @task.status = nil
    assert @task.invalid?
    assert @task.errors[:status].any?

    @task.status = 2
    assert @task.invalid?
    assert @task.errors[:status].any?

    @task.status = 'BOGUS'
    assert @task.invalid?
    assert @task.errors[:status].any?

    @task.status = 'COMPLETED'
    @user.tasks << @task
    assert @task.valid?
  end

  test 'current? method should return true for due dates on or before today' do
    @user.tasks << @task
    today = Date.current.to_fs(:db)
    @task.due_at = today
    assert @task.current?(today)

    yesterday = Date.yesterday.to_fs(:db)
    @task.due_at = yesterday
    assert @task.current?(today)

    tomorrow = Date.tomorrow.to_fs(:db)
    @task.due_at = tomorrow
    assert_not @task.current?(today)
  end

  test 'current? method should return true for tasks with no due date set' do
    @user.tasks << @task
    @task.due_at = nil
    assert @task.current?(Date.current.to_fs(:db))
  end

  test 'upcoming? method should return true for due dates after today' do
    @user.tasks << @task
    today = Date.current.to_fs(:db)
    @task.due_at = today
    assert_not @task.upcoming?(today)

    yesterday = Date.yesterday.to_fs(:db)
    @task.due_at = yesterday
    assert_not @task.upcoming?(today)

    tomorrow = Date.tomorrow.to_fs(:db)
    @task.due_at = tomorrow
    assert @task.upcoming?(today)
  end

  test 'recurring? method should return true for task summaries that include recurring syntax' do
    @user.tasks << @task
    @task.due_at = Date.current.to_fs(:db)

    @task.summary = 'A recurring task (every day)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every week)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every month)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every year)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every 2 days)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every 33 weeks)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every 4 months)'
    assert @task.recurring?

    @task.summary = 'A recurring task (every 15 years)'
    assert @task.recurring?

    @task.summary = 'A non-recurring task (every days)'
    assert_not @task.recurring?

    @task.summary = 'A non-recurring task (every 2 week)'
    assert_not @task.recurring?
  end

  test 'recurring? method should return false for tasks with no summary set' do
    @user.tasks << @task
    @task.summary = nil
    assert_not @task.recurring?
  end

  test 'recurring? method should return false for tasks with empty summary' do
    @user.tasks << @task
    @task.summary = ' '
    assert_not @task.recurring?
  end

  test 'recurring_period method should return the correct period for recurring tasks' do
    @user.tasks << @task
    @task.summary = 'A recurring task (every day)'
    assert_equal 1.day, @task.recurring_period

    @task.summary = 'A recurring task (every week)'
    assert_equal 1.week, @task.recurring_period

    @task.summary = 'A recurring task (every month)'
    assert_equal 1.month, @task.recurring_period

    @task.summary = 'A recurring task (every year)'
    assert_equal 1.year, @task.recurring_period

    @task.summary = 'A recurring task (every 2 days)'
    assert_equal 2.days, @task.recurring_period

    @task.summary = 'A recurring task (every 33 weeks)'
    assert_equal 33.weeks, @task.recurring_period

    @task.summary = 'A recurring task (every 4 months)'
    assert_equal 4.months, @task.recurring_period

    @task.summary = 'A recurring task (every 15 years)'
    assert_equal 15.years, @task.recurring_period

    @task.summary = 'A non-recurring task (every days)'
    assert_nil @task.recurring_period

    @task.summary = 'A non-recurring task (every 2 week)'
    assert_nil @task.recurring_period
  end

  test 'search method should return relevant search matches' do
    assert_equal [], @user.tasks.search('bogus', 'all', 'All', nil)

    @user.tasks << @task
    @tc_uncategorized = TaskCategory.new(name: 'Uncategorized')
    assert_equal 1, @user.tasks.search('first', 'all', 'All', nil).length
    assert_equal 1, @user.tasks.search('first', 'all', @tc_work.id, nil).length
    assert_equal 1, @user.tasks.search('first', 'incomplete', 'All', nil).length
    assert_equal 0, @user.tasks.search('first', 'completed', 'All', nil).length
    assert_equal 0, @user.tasks.search('first', 'completed',
                                       @tc_uncategorized.id, nil).length
  end

  test 'search method with custom sort should return results in the correct order' do
    @user.tasks << @task
    task2 = Task.new(summary: 'A second task',
                     task_category_id: @tc_work.id,
                     priority: 2,
                     status: 'INCOMPLETE',
                     due_at: Date.yesterday.to_fs(:db))
    @user.tasks << task2
    task3 = Task.new(summary: 'A third task',
                     task_category_id: @tc_work.id,
                     priority: 1,
                     status: 'INCOMPLETE',
                     due_at: Date.current.to_fs(:db))
    @user.tasks << task3
    results = @user.tasks.search('task', 'incomplete', 'All', 'priority-desc')
    assert_equal [@task.id, task2.id, task3.id], results.map(&:id)

    results = @user.tasks.search('task', 'incomplete', 'All', 'priority-asc')
    assert_equal [task3.id, task2.id, @task.id], results.map(&:id)

    results = @user.tasks.search('task', 'incomplete', 'All', 'due-date-asc')
    assert_equal [@task.id, task2.id, task3.id], results.map(&:id)

    results = @user.tasks.search('task', 'incomplete', 'All', 'due-date-desc')
    assert_equal [task3.id, task2.id, @task.id], results.map(&:id)

    # If a malicious sort_by value is passed, the results should be empty
    results = @user.tasks.search('task', 'incomplete', 'All', 'bogus-sort')
    assert_equal [], results
  end

  test 'toggle_status method should change status from INCOMPLETE to COMPLETED and vice versa' do
    @user.tasks << @task
    assert_equal 'INCOMPLETE', @task.status
    assert_nil @task.completed_at

    @task.toggle_status
    assert_equal 'COMPLETED', @task.status
    assert_not_nil @task.completed_at

    @task.toggle_status
    assert_equal 'INCOMPLETE', @task.status
    assert_nil @task.completed_at
  end

  test 'status_as_boolean method should return true for COMPLETED status and false for INCOMPLETE status' do
    @user.tasks << @task
    assert_equal false, @task.status_as_boolean

    @task.toggle_status
    assert_equal true, @task.status_as_boolean

    @task.status = 'BOGUS'
    assert_raises(RuntimeError) { @task.status_as_boolean }
  end

  test 'self.future? method should return tasks with due dates after today and status INCOMPLETE' do
    @user.tasks << @task
    today = Date.current.to_fs(:db)

    @task.due_at = Date.tomorrow.to_fs(:db)
    @task.status = 'INCOMPLETE'
    @task.save!
    assert_equal 1, @user.tasks.future(today).length

    @task.due_at = Date.yesterday.to_fs(:db)
    @task.save!
    assert_equal 0, @user.tasks.future(today).length

    @task.due_at = Date.tomorrow.to_fs(:db)
    @task.status = 'COMPLETED'
    @task.save!
    assert_equal 0, @user.tasks.future(today).length
  end

  test 'self.overdue? method should return tasks with due dates before today and status INCOMPLETE' do
    @user.tasks << @task
    today = Date.current.to_fs(:db)

    @task.due_at = Date.yesterday.to_fs(:db)
    @task.status = 'INCOMPLETE'
    @task.save!
    assert_equal 1, @user.tasks.overdue(today).length

    @task.due_at = Date.tomorrow.to_fs(:db)
    @task.save!
    assert_equal 0, @user.tasks.overdue(today).length

    @task.due_at = Date.yesterday.to_fs(:db)
    @task.status = 'COMPLETED'
    @task.save!
    assert_equal 0, @user.tasks.overdue(today).length
  end

  test 'self.completed_today? method should return tasks completed today' do
    @user.tasks << @task
    today_start = DateTime.now.beginning_of_day
    today_end = DateTime.now.end_of_day
    yesterday = DateTime.now.yesterday
    tomorrow = DateTime.now.tomorrow

    @task.status = 'COMPLETED'
    @task.completed_at = DateTime.now
    @task.save!
    assert_equal 1, @user.tasks.completed_today(today_start, today_end).length

    @task.completed_at = yesterday
    @task.save!
    assert_equal 0, @user.tasks.completed_today(today_start, today_end).length
    @task.completed_at = tomorrow
    @task.save!
    assert_equal 0, @user.tasks.completed_today(today_start, today_end).length

    @task.status = 'INCOMPLETE'
    @task.completed_at = DateTime.now
    @task.save!
    assert_equal 0, @user.tasks.completed_today(today_start, today_end).length
  end

  test 'self.category method should return tasks in the specified task category' do
    @user.tasks << @task
    @tc_personal = TaskCategory.new(name: 'Personal')
    @user.task_categories << @tc_personal
    @tc_personal.save!
    @user.save!

    assert_equal 1, @user.tasks.category(@tc_work.id).length
    assert_equal 0, @user.tasks.category(@tc_personal.id).length

    @task.task_category_id = @tc_personal.id
    @task.save!
    assert_equal 0, @user.tasks.category(@tc_work.id).length
    assert_equal 1, @user.tasks.category(@tc_personal.id).length
  end

  test 'self.move_to_category method should reassign all tasks in the collection to the specified task category' do
    # Create three tasks in the Work category. Then move them to the
    # Personal category.
    @user.tasks << @task
    task2 = Task.new(summary: 'A second task',
                     task_category_id: @tc_work.id,
                     priority: 2,
                     status: 'INCOMPLETE')
    @user.tasks << task2
    task3 = Task.new(summary: 'A third task',
                     task_category_id: @tc_work.id,
                     priority: 1,
                     status: 'INCOMPLETE')
    @user.tasks << task3
    @tc_personal = TaskCategory.new(name: 'Personal')
    @user.task_categories << @tc_personal
    @tc_personal.save!
    @user.save!
    assert_equal 3, @user.tasks.category(@tc_work.id).length

    Task.where(id: [@task.id, task2.id, task3.id]).move_to_category(@tc_personal.id)
    assert_equal 0, @user.tasks.category(@tc_work.id).length
    assert_equal 3, @user.tasks.category(@tc_personal.id).length
  end

  # TODO: STILL NEED TESTING: self.current, self.current_with_due_dates
end
