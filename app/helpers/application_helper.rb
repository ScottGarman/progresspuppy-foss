module ApplicationHelper
  # Return the the tasks_rul if the user is logged in,
  # and root_path otherwise.
  def smart_root_path
    return tasks_path if logged_in?

    root_path
  end

  # Check the object passed for validation errors on its attribute, and
  # return the appropriate Bootstrap form validity class
  def form_validity_class(obj, attribute)
    cssclass = ''
    cssclass = 'is-invalid' unless obj.errors[attribute].blank?

    cssclass
  end

  # Return an HTML string of the first model validation error on the
  # given attribute
  def validation_error_html(obj, attribute, displayname)
    return unless obj.errors.any?
    return if obj.errors[attribute].blank?

    # When there are multiple validation messages, this prints the first one
    "<p id='#{attribute}_error_msg' class='error-msg'>#{displayname}" \
    " #{obj.errors[attribute][0]}</p>"
  end

  # Return the hidden-by-default CSS class if the new task form should
  # be hidden based on the display-new-task-form cookie
  def new_task_form_display_class
    return 'hide-by-default' if cookies[:display_new_task_form] == 'false'

    ''
  end

  # Return a human-readable relative date string
  def relative_due_date(dateval, timezone)
    return '' if dateval.nil?

    return 'Due Today' if dateval == Time.now.in_time_zone(timezone).to_date
    return 'Due Tomorrow' if dateval == Time.now.in_time_zone(timezone).to_date
                                            .tomorrow

    # Otherwise, just return it as-is
    "Due #{dateval}"
  end
end
