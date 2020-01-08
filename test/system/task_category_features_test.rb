require 'application_system_test_case'

class TaskCategoryFeaturesTest < ApplicationSystemTestCase
  test 'user can cancel editing a task category' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    click_link 'Settings'
    assert has_selector?(:link_or_button, 'Task Categories')
    click_link 'Task Categories'
    assert_current_path task_categories_path

    # Create a TC to edit
    fill_in 'task_category_name', with: 'Work'
    click_button 'Save'

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
end
