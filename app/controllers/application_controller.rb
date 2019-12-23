class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  private

  # Confirms a logged-in user
  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = 'Please log in.'
    redirect_to login_url
  end

  # Return a DB formatted date string in the current user's time zone for today
  def today_db
    Time.now.in_time_zone(current_user.time_zone).to_date.to_s(:db)
  end

  # Return a DB formatted datetime string in the current user's time zone
  # for the start of today
  def today_start_db
    DateTime.now.in_time_zone(current_user.time_zone).beginning_of_day.to_s(:db)
  end

  # Return a DB formatted datetime string in the current user's time zone
  # for the end of today
  def today_end_db
    DateTime.now.in_time_zone(current_user.time_zone).end_of_day.to_s(:db)
  end

  # Return the base message with optional references to the view the task change
  # occurred on (sometimes task changes won't appeaar on the current view)
  def task_change_flash_msg(task, tasks_view, base_msg)
    msg = base_msg
    if task.current?(today_db) && %w[upcoming search].include?(tasks_view)
      msg = "#{base_msg} (in Today's Tasks list)"
    elsif task.upcoming?(today_db) && %w[index search].include?(tasks_view)
      msg = "#{base_msg} (in Upcoming Tasks list)"
    end

    msg
  end
end
