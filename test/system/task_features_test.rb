require 'application_system_test_case'

class TaskFeaturesTest < ApplicationSystemTestCase
  test 'ensure the new task form visibility behaves consistently' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # The new task form should be visible by default
    assert has_selector?('div#new_task_container')

    # The new task form should remain visible on Upcoming Tasks
    click_link 'Upcoming Tasks'
    assert_current_path upcoming_tasks_path
    assert has_selector?('div#new_task_container')

    # ...and again for New Tasks when the tab was clicked
    click_link "Today's Tasks"
    assert_current_path tasks_path
    assert has_selector?('div#new_task_container')

    # Close the new task form
    click_link 'toggle_new_task_form_control_link'
    assert_current_path tasks_path
    sleep 1
    assert has_no_selector?('div#new_task_container')

    # The new task form should remain invisible on Upcoming Tasks
    click_link 'Upcoming Tasks'
    assert_current_path upcoming_tasks_path
    assert has_no_selector?('div#new_task_container')

    # ...and again for New Tasks when the tab was clicked
    click_link "Today's Tasks"
    assert_current_path tasks_path
    assert has_no_selector?('div#new_task_container')

    # Open the new task form
    click_link 'toggle_new_task_form_control_link'
    assert_current_path tasks_path
    sleep 1
    assert has_selector?('div#new_task_container')

    # The new task form should remain visible on Upcoming Tasks
    click_link 'Upcoming Tasks'
    assert_current_path upcoming_tasks_path
    assert has_selector?('div#new_task_container')

    # ...and again for New Tasks when the tab was clicked
    click_link "Today's Tasks"
    assert_current_path tasks_path
    assert has_selector?('div#new_task_container')
  end

  test 'submitting the new task form with an empty summary shows validation errors' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # Clear the summary field and submit
    fill_in 'task_summary', with: ''
    click_button 'Create Task'

    # Validation error should be displayed
    assert_selector 'p#summary_error_msg', text: /can't be blank/
  end
end
