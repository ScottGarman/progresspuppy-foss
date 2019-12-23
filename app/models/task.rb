class Task < ApplicationRecord
  belongs_to :task_category
  belongs_to :user

  # Validation
  STATUS_TYPES = %w[INCOMPLETE COMPLETED].freeze

  validates_presence_of :user_id

  validates :summary, presence: true,
                      length: { maximum: 150 }

  validates :priority, presence: true,
                       inclusion: { in: 1..3 }

  validates :status, presence: true,
                     inclusion: { in: STATUS_TYPES }

  # Scopes
  scope :incomplete,  -> { where(status: :INCOMPLETE) }
  scope :completed,   -> { where(status: :COMPLETED) }
  scope :no_due_date, -> { where('due_at IS NULL') }

  def self.category(tc_id)
    where(task_category_id: tc_id)
  end

  # Reassign a task collection to a different Task Category
  def self.move_to_category(tc_id)
    update_all(task_category_id: tc_id)
  end

  # today_db should be today's date in database format (yyyy-mm-dd). It's
  # passed as an argument to allow its caller to apply the user's time
  # zone to the date.
  #
  # Current tasks are due today or before, or have no due date set
  def self.current(today_db)
    incomplete.where('due_at <= ?', today_db)
              .order(due_at: :asc, priority: :asc) +
      incomplete.no_due_date.order(priority: :asc)
  end

  # today_db should be today's date in database format (yyyy-mm-dd). It's
  # passed as an argument to allow its caller to apply the user's time
  # zone to the date.
  def self.current_with_due_dates(today_db)
    incomplete.where('due_at <= ?', today_db)
              .order(due_at: :asc, priority: :asc)
  end

  # Boolean method that returns whether the task is "current", i.e. would be
  # displayed in the Current Tasks tab (instead of Upcoming Tasks). today_db
  # should be today's date in database format (yyyy-mm-dd). It's passed as an
  # argument to allow its caller to apply the user's time zone to the date.
  def current?(today_db)
    due_at.to_s <= today_db || due_at.nil?
  end

  # Boolean method that returns whether the task is "upcoming", i.e. would be
  # displayed in the Upcoming Tasks tab (instead of Current Tasks). today_db
  # should be today's date in database format (yyyy-mm-dd). It's passed as an
  # argument to allow its caller to apply the user's time zone to the date.
  def upcoming?(today_db)
    due_at.to_s > today_db
  end

  # today_db should be today's date in database format (yyyy-mm-dd). It's
  # passed as an arguent to allow its caller to apply the user's time
  # zone to the date.
  def self.overdue(today_db)
    incomplete.where('due_at < ?', today_db).order(due_at: :asc, priority: :asc)
  end

  # today_db should be today's date in database format (yyyy-mm-dd). It's
  # passed as an argument to allow its caller to apply the user's time
  # zone to the date.
  def self.future(today_db)
    incomplete.where('due_at > ?', today_db).order(due_at: :asc, priority: :asc)
  end

  # today_start_db and today_end_db should be DateTimes of the start and
  # end of today. They are passed as arguments to allow its caller to
  # apply the user's time zone to the dates.
  def self.completed_today(today_start_db, today_end_db)
    completed.where('completed_at BETWEEN ? AND ?', today_start_db,
                    today_end_db).order(due_at: :asc, priority: :asc)
  end

  def self.search(summary_terms, completed_status, category_id, sort_by)
    tasks = all
    tasks = tasks.where('summary LIKE ?', "%#{summary_terms}%") unless summary_terms.empty?
    tasks = tasks.completed if completed_status == 'completed'
    tasks = tasks.incomplete if completed_status == 'incomplete'
    tasks = tasks.category(category_id) if category_id != 'All'

    return tasks.order('due_at asc') if sort_by.nil?

    # customize the sort order
    return tasks.order(due_at: :asc) if sort_by == 'due-date-asc'
    return tasks.order(due_at: :desc) if sort_by == 'due-date-desc'
    return tasks.order(priority: :asc) if sort_by == 'priority-asc'
    return tasks.order(priority: :desc) if sort_by == 'priority-desc'

    # if we've reached this point, something isn't right (a malicious user may
    # be messing with the sort_by string), so to prevent a site crash, just
    # return an empty array
    []
  end

  # Returns a boolean based on the tasks' status: INCOMPLETE as false,
  # COMPLETED as true
  def status_as_boolean
    return false if status == 'INCOMPLETE'
    return true if status == 'COMPLETED'

    false
  end

  def toggle_status
    if status == 'INCOMPLETE'
      update_attribute(:status, 'COMPLETED')
      update_attribute(:completed_at, Time.now)
    else
      update_attribute(:status, 'INCOMPLETE')
      update_attribute(:completed_at, nil)
    end
  end
end
