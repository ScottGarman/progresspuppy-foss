require 'application_system_test_case'

class TaskDatepickerTest < ApplicationSystemTestCase
  test 'datepicker appears when clicking the due at field on the new task form' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    assert_selector 'div#new_task_container'

    # Click the Due at date field to trigger the datepicker
    find('#new_task_due_at').click

    # The bootstrap-datepicker should appear
    assert_selector '.datepicker-dropdown', visible: true
  end

  test 'datepicker appears when clicking the due at field on the edit task form' do
    aaronpk = users(:aaronpk)
    log_in_as(aaronpk)

    # Click the edit pencil icon on the first displayed task
    first('.task-edit-icon').click

    # Wait for the AJAX edit form to load
    assert_selector '.editable-task', visible: true

    # Click the date picker input field within the edit form
    find('.editable-task .date-picker-input').click

    # The bootstrap-datepicker should appear
    assert_selector '.datepicker-dropdown', visible: true
  end
end
