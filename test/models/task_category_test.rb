require 'test_helper'

class TaskCategoryTest < ActiveSupport::TestCase
  def setup
    @user = User.new(first_name: 'Bubba',
                     last_name: 'Jones',
                     email: 'bubbajones@example.com',
                     password: 'foobarbaz123',
                     password_confirmation: 'foobarbaz123',
                     accepted_tos: true)
    @user.save!

    @tc = TaskCategory.new(name: 'Work')
  end

  test 'should be valid' do
    @user.task_categories << @tc
    assert @tc.valid?
  end

  test 'a TaskCategory must be associated with a User' do
    assert @tc.invalid?
    assert @tc.errors[:user_id].any?
  end

  test 'name should be present and not empty' do
    @user.task_categories << @tc
    @tc.name = '  '
    assert @tc.invalid?
    assert @tc.errors[:name].any?
  end

  test 'name should not be too long' do
    @user.task_categories << @tc
    @tc.name = 'a' * 51
    assert @tc.invalid?
    assert @tc.errors[:name].any?

    @tc.name = 'a' * 50
    assert @tc.valid?
  end

  test 'duplicate TaskCategory names cannot exist for the same User' do
    @user.task_categories << @tc
    assert_not_nil @user.task_categories.find_by_name('Work')

    tc2 = TaskCategory.new(name: 'Work')
    assert_equal @user.task_categories.count, 2
    @user.task_categories << tc2
    assert tc2.invalid?
    assert tc2.errors[:name].any?
  end
end
