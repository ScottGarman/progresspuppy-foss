module TasksHelper
  # Return CSS classes for this task based on its priority and whether the task
  # is completed.
  def task_status_class(task)
    cssclass = ''
    cssclass += 'task-priority1 ' if task.priority == 1
    cssclass += 'task-priority2 ' if task.priority == 2
    cssclass += 'task-completed ' if task.status == 'COMPLETED'

    cssclass
  end

  # Return the correct path for the Cancel link on the edit task form,
  # based on which view the user is editing from.
  def cancel_edit_task_path
    case params[:tasks_view]
    when 'search'
      search_tasks_path(
        search_terms: params[:search_terms],
        tasks_filter: params[:tasks_filter],
        task_category_filter: params[:task_category_filter],
        page: params[:page]
      )
    when 'upcoming'
      upcoming_tasks_path
    else
      tasks_path
    end
  end

  # Return an options_for_select array with task sorting options
  def task_sort_options
    [['Due Date - Oldest First', 'due-date-asc'],
     ['Due Date - Newest First', 'due-date-desc'],
     ['Priority - Higest First', 'priority-asc'],
     ['Priority - Lowest First', 'priority-desc']]
  end
end
