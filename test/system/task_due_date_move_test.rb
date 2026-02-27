require 'application_system_test_case'

class TaskDueDateMoveTest < ApplicationSystemTestCase
  test 'task disappears from Today list when due date is changed to a future date' do
    aaronpk = users(:aaronpk)
    task = tasks(:aaronpk_task1)
    future_date = (Date.current + 7.days).strftime('%Y-%m-%d')

    log_in_as(aaronpk)

    # Confirm the task is visible in Today's Tasks
    assert_text task.summary

    # Click the edit pencil icon on this specific task
    within "#task_#{task.id}_container" do
      find('.task-edit-icon').click
    end

    # Wait for the edit form to load via Turbo Frame
    assert_selector "#editable_task_#{task.id}", visible: true

    # Change the due date to a future date via JS to avoid datepicker
    # intercepting keystrokes and mangling the value
    date_field_id = "editable_task_#{task.id}_date_picker"
    execute_script("document.getElementById('#{date_field_id}').value = '#{future_date}'")

    # Submit the update
    find("#editable_task_#{task.id} .update-task-btn").click

    # The task should be removed from Today's Tasks
    assert_no_text task.summary

    # A flash message should indicate the task moved to Upcoming
    assert_text 'Task updated'
    assert_text 'Upcoming Tasks list'
  end

  test 'task disappears from Today list when due date is changed to future after a previous edit' do
    aaronpk = users(:aaronpk)
    task = tasks(:aaronpk_task1)
    future_date = (Date.current + 7.days).strftime('%Y-%m-%d')

    log_in_as(aaronpk)

    # Confirm the task is visible in Today's Tasks
    assert_text task.summary

    # --- First edit: change the summary (task stays in Today's Tasks) ---
    within "#task_#{task.id}_container" do
      find('.task-edit-icon').click
    end
    assert_selector "#editable_task_#{task.id}", visible: true

    within "#editable_task_#{task.id}" do
      fill_in 'task_summary', with: "#{task.summary} edited"
      click_button 'Update Task'
    end

    # Task should still be in Today's Tasks with the updated summary
    assert_text "#{task.summary} edited"
    assert_text 'Task updated'

    # --- Second edit: change due date to future (task should disappear) ---
    within "#task_#{task.id}_container" do
      find('.task-edit-icon').click
    end
    assert_selector "#editable_task_#{task.id}", visible: true

    date_field_id = "editable_task_#{task.id}_date_picker"
    execute_script("document.getElementById('#{date_field_id}').value = '#{future_date}'")

    find("#editable_task_#{task.id} .update-task-btn").click

    # The task should be removed from Today's Tasks
    assert_no_text "#{task.summary} edited"

    # A flash message should indicate the task moved to Upcoming
    assert_text 'Task updated'
    assert_text 'Upcoming Tasks list'
  end
end
