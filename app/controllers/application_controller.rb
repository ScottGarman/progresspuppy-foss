class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  # Handle CSRF token failures gracefully
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_token

  private

  # Handle invalid CSRF token (expired session, bot attempts, etc.)
  def handle_invalid_token
    flash[:warning] = 'Your session has expired. Please log in again.'
    redirect_to login_url
  end

  # Confirms a logged-in user
  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = 'Please log in.'
    redirect_to login_url
  end

  # Return a DB formatted date string in the current user's time zone for today
  def today_db
    Time.now.in_time_zone(current_user.time_zone).to_date.to_fs(:db)
  end

  # Return a DB formatted datetime string in the current user's time zone
  # for the start of today
  def today_start_db
    DateTime.now.in_time_zone(current_user.time_zone).beginning_of_day.to_fs(:db)
  end

  # Return a DB formatted datetime string in the current user's time zone
  # for the end of today
  def today_end_db
    DateTime.now.in_time_zone(current_user.time_zone).end_of_day.to_fs(:db)
  end

  # Return the base message with optional references to the view the task was
  # updated from (the task remains visible in that view after the update)
  def task_change_flash_msg(task, tasks_view, base_msg)
    msg = base_msg
    if task.current?(today_db) && tasks_view == 'upcoming'
      msg = "#{base_msg} (in Today's Tasks list)"
    elsif task.upcoming?(today_db) && tasks_view == 'index'
      msg = "#{base_msg} (in Upcoming Tasks list)"
    end

    msg
  end

  # Return a flash message for a newly created task, noting which view it
  # can be found in when created from a view that won't show it (e.g. Search)
  def new_task_flash_msg(task, tasks_view)
    msg = 'New task created'
    if task.current?(today_db) && %w[upcoming search].include?(tasks_view)
      msg = 'New task created (in Today\'s Tasks list)'
    elsif task.upcoming?(today_db) && %w[index search].include?(tasks_view)
      msg = 'New task created (in Upcoming Tasks list)'
    end

    msg
  end
end
