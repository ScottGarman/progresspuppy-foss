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
    today = Date.today.to_s(:db)
    @task.due_at = today
    assert @task.current?(today)

    yesterday = Date.yesterday.to_s(:db)
    @task.due_at = yesterday
    assert @task.current?(today)

    tomorrow = Date.tomorrow.to_s(:db)
    @task.due_at = tomorrow
    assert_not @task.current?(today)
  end

  test 'current? method should return true for tasks with no due date set' do
    @user.tasks << @task
    @task.due_at = nil
    assert @task.current?(Date.today.to_s(:db))
  end

  test 'upcoming? method should return true for due dates after today' do
    @user.tasks << @task
    today = Date.today.to_s(:db)
    @task.due_at = today
    assert_not @task.upcoming?(today)

    yesterday = Date.yesterday.to_s(:db)
    @task.due_at = yesterday
    assert_not @task.upcoming?(today)

    tomorrow = Date.tomorrow.to_s(:db)
    @task.due_at = tomorrow
    assert @task.upcoming?(today)
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

  # TODO: STILL NEED TESTING: self.category, self.move_to_category,
  # self.current, self.current_with_due_dates, self.overdue, self.future,
  # self.completed_today, status_as_boolean, toggle_status
end
