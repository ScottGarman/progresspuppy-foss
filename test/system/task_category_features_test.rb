require 'application_system_test_case'

class TaskCategoryFeaturesTest < ApplicationSystemTestCase
  test 'user can cancel editing a task category' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    click_button 'Settings'
    click_link 'Task Categories'
    assert_current_path task_categories_path

    # Create a TC to edit
    fill_in 'task_category_name', with: 'Work'
    click_button 'Save'

    # Wait for the flash message that confirms creation completed
    assert has_content?('New task category created')

    # Verify the TC exists in the database
    tc_work = donpdonp.task_categories.find_by_name('Work')
    assert_not_nil tc_work
    assert_equal donpdonp.task_categories.size, 2

    # Since at this point there should only be one TC displayed (Uncategorized
    # exists but is not shown), we don't have to get too specific with the
    # selectors here
    find('img.task-category-edit-icon').click
    assert_no_selector "div#display_task_category_#{tc_work.id}"
    click_link 'Cancel'
    assert_selector "div#display_task_category_#{tc_work.id}"
    assert has_no_content?('Cancel')
  end

  test 'successfully editing a task category shows flash alert' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    click_button 'Settings'
    click_link 'Task Categories'
    assert_current_path task_categories_path

    # Create a TC to edit
    fill_in 'task_category_name', with: 'Work'
    click_button 'Save'
    assert has_content?('New task category created')

    tc_work = donpdonp.task_categories.find_by_name('Work')

    # Click edit
    find('img.task-category-edit-icon').click

    within "#editable_task_category_#{tc_work.id}" do
      fill_in 'task_category_name', with: 'Personal'
      click_button 'Update Category'
    end

    # Flash alert should appear next to the "Your Task Categories" heading
    assert has_content?('Task Category updated')

    # The task category should be in display mode with the updated name
    assert has_content?('Personal')
    assert_no_selector "div#editable_task_category_#{tc_work.id}"
  end

  test 'editing a task category with empty name shows validation error inline' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    click_button 'Settings'
    click_link 'Task Categories'
    assert_current_path task_categories_path

    # Create a TC to edit
    fill_in 'task_category_name', with: 'Work'
    click_button 'Save'
    assert has_content?('New task category created')

    tc_work = donpdonp.task_categories.find_by_name('Work')

    # Click edit
    find('img.task-category-edit-icon').click

    within "#editable_task_category_#{tc_work.id}" do
      # Clear the name field and submit
      fill_in 'task_category_name', with: ''
      click_button 'Update Category'
    end

    # Validation error should be displayed inline
    assert_selector 'p#name_error_msg', text: /can't be blank/

    # The form should still be visible (not reverted to display mode)
    assert_selector "div#editable_task_category_#{tc_work.id}"

    # The rest of the page should still be intact (not replaced by just the edit form)
    assert has_content?('Define a New Task Category')
    assert_selector 'input#task_category_name'
  end
end
