class TasksController < ApplicationController
  before_action :logged_in_user

  def index
    @new_task = Task.new
    tc_filter = params[:category]
    if tc_filter.nil?
      @current_tasks = current_user.tasks.current(today_db)
                                   .paginate(page: params[:page], per_page: 20)
    else
      tc_id = current_user.task_categories.find_by(name: tc_filter)
      @current_tasks = current_user.tasks.category(tc_id).current(today_db)
                                   .paginate(page: params[:page], per_page: 20)
    end

    @completed_tasks = current_user.tasks.completed_today(today_start_db,
                                                          today_end_db)
    @overdue_tasks = current_user.tasks.overdue(today_db).count
    @quote = random_quote
    @awwyiss_modal = random_awwyiss_modal
  end

  def upcoming
    @new_task = Task.new
    tc_filter = params[:category]
    if tc_filter.nil?
      @future_tasks = current_user.tasks.future(today_db)
                                  .paginate(page: params[:page], per_page: 20)
    else
      tc_id = current_user.task_categories.find_by(name: tc_filter)
      @future_tasks = current_user.tasks.category(tc_id).future(today_db)
                                  .paginate(page: params[:page], per_page: 20)
    end
    @quote = random_quote
    @awwyiss_modal = random_awwyiss_modal
  end

  def show
    @task = current_user.tasks.find_by(id: params[:id])
    return unless @task.nil?

    flash[:danger] = 'Task not found'
    redirect_to_correct_tasks_tab && return
  end

  def new
    @new_task = Task.new
  end

  def create
    @new_task = current_user.tasks.build(task_params)
    if @new_task.save
      flash[:success] = task_change_flash_msg(@new_task, params[:tasks_view],
                                              'New task created')
      redirect_to_correct_tasks_tab
    else
      @new_task.destroy!
      @current_tasks = current_user.tasks.current(today_db)
                                   .paginate(page: params[:page], per_page: 20)
      @completed_tasks = current_user.tasks
                                     .completed_today(today_start_db,
                                                      today_end_db)
      @future_tasks = current_user.tasks.future(today_db)
                                  .paginate(page: params[:page], per_page: 20)
      @overdue_tasks = current_user.tasks.overdue(today_db).count
      @search_results = []
      @quote = random_quote
      @awwyiss_modal = random_awwyiss_modal
      render_correct_tasks_tab
    end
  end

  def edit
    @task = current_user.tasks.find_by(id: params[:id])
    return unless @task.nil?

    flash[:danger] = 'Task not found'
    redirect_to_correct_tasks_tab && return
  end

  def update
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Updating task failed: task not found'
      redirect_to_correct_tasks_tab && return
    end

    priority_was = @task.priority
    if @task.update(task_params)
      @tasks_view = params[:tasks_view]
      @today_db = today_db
      @flash_msg = task_change_flash_msg(@task, @tasks_view, 'Task updated')
      # When priority changes, the task's position in the sorted list changes.
      # We need to reload the full task list so the Turbo Stream response can
      # replace the entire list (with correct ordering) rather than just
      # updating the individual task in-place.
      @priority_changed = @task.priority != priority_was
      if @priority_changed
        tc_filter = params[:category]
        if @tasks_view == 'index'
          tc_id = current_user.task_categories.find_by(name: tc_filter)
          @current_tasks = current_user.tasks.then { |t| tc_filter ? t.category(tc_id) : t }
                                             .current(@today_db)
                                             .paginate(page: params[:page], per_page: 20)
        elsif @tasks_view == 'upcoming'
          tc_id = current_user.task_categories.find_by(name: tc_filter)
          @future_tasks = current_user.tasks.then { |t| tc_filter ? t.category(tc_id) : t }
                                            .future(@today_db)
                                            .paginate(page: params[:page], per_page: 20)
        end
      end
      respond_to do |f|
        f.turbo_stream
        f.html do
          flash[:success] = task_change_flash_msg(@task, params[:tasks_view],
                                                  'Task updated')
          redirect_to_correct_tasks_tab
        end
      end
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Deleting task failed: task not found'
      redirect_to_correct_tasks_tab && return
    end

    @task.destroy

    respond_to do |f|
      f.turbo_stream
      f.html do
        flash[:success] = 'Task deleted'
        redirect_to_correct_tasks_tab
      end
    end
  end

  def toggle_task_status
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Changing task status failed: task not found'
      redirect_to(tasks_path) && return
    end

    @task.toggle_status
    @task.reload

    @current_tasks = current_user.tasks.current(today_db)
                                 .paginate(page: params[:page], per_page: 20)
    @completed_tasks = current_user.tasks.completed_today(today_start_db,
                                                          today_end_db)
    @awwyiss_modal = random_awwyiss_modal

    # When completing a recurring task, create an identical task with the due date
    # set to the current time, advanced by the recurrance period
    if @task.status == 'COMPLETED' && @task.recurring?
      new_task = @task.dup
      new_task.due_at = (@task.due_at || Time.zone.now.to_date) + @task.recurring_period
      new_task.status = 'INCOMPLETE'
      new_task.completed_at = nil
      new_task.save!

      @new_task_reminder = "Note: Created recurring task due #{new_task.due_at}"
    end

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_to tasks_path }
    end
  end

  def advance_overdue_tasks
    num_overdue_tasks = current_user.tasks.overdue(today_db).count
    current_user.tasks.current_with_due_dates(today_db).update(due_at: today_db)
    @current_tasks = current_user.tasks.current(today_db)
                                 .paginate(page: params[:page], per_page: 20)
    flash[:success] = "Updated #{num_overdue_tasks} task due " \
                      "#{'date'.pluralize(num_overdue_tasks)} to today"
    redirect_to tasks_path(page: params[:page])
  end

  def search
    @quote = random_quote
    @awwyiss_modal = random_awwyiss_modal
    @new_task = Task.new

    if params[:search_terms]
      @search_results = current_user.tasks.search(params[:search_terms],
                                                  params[:tasks_filter],
                                                  params[:task_category_filter],
                                                  params[:sort_by]).paginate(
                                                    page: params[:page],
                                                    per_page: 20
                                                  )
    else
      @search_results = []
    end
  end

  private

  def task_params
    params.require(:task).permit(:summary, :task_category_id, :priority,
                                 :status, :due_at, :completed_at)
  end

  # Task operations can be done from either the current tasks view
  # (index), upcoming tasks view, or search view. This ensures we redirect
  # to the correct tasks view we originated from.
  def redirect_to_correct_tasks_tab
    if params[:tasks_view] == 'upcoming'
      redirect_to upcoming_tasks_path(category: params[:category],
                                      page: params[:page])
    elsif params[:tasks_view] == 'search'
      redirect_to search_tasks_path(search_terms: params[:search_terms],
                                    tasks_filter: params[:tasks_filter],
                                    task_category_filter:
                                      params[:task_category_filter])
    else
      redirect_to tasks_path(category: params[:category], page: params[:page])
    end
  end

  # This serves the same purpose as redirect_to_correct_tasks_tab above, but
  # is used when only rendering the view rather than redirecting to it.
  def render_correct_tasks_tab
    # Only explicitly set view to a known set of views, otherwise an attacker
    # could render any view by setting params[:tasks_view]
    case params[:tasks_view]
    when 'upcoming'
      view = 'upcoming'
    when 'search'
      view = 'search'
    else
      view = 'index'
    end

    render(view, status: :unprocessable_entity)
  end

  def random_quote
    # Use pluck to only get the ids from the quotes table and not load
    # all of the entries into memory:
    quote_ids = current_user.quotes.pluck(:id)
    return nil if quote_ids.empty?

    # Use sample to return a random id from the array:
    quote = current_user.quotes.find(quote_ids.sample)

    if quote_ids.length < 5 || current_user.quote_history.length < 3
      current_user.quote_history.shift if current_user.quote_history.length > 2
      current_user.quote_history << quote.id
      current_user.save!
      return quote
    end

    # Ensure we aren't repeating one of the last 3 quotes the user has seen:
    quote = current_user.quotes.find(quote_ids.sample) while current_user.quote_history.include?(quote.id)

    current_user.quote_history.shift
    current_user.quote_history << quote.id
    current_user.save!
    quote
  end

  # Returns a list of meme modal template names that can be shown.
  def meme_modal_list
    # Customize your memes by adding partial templates in app/views/tasks/ and
    # reference them here:
    %w[awwyiss_modal_bravocado
       awwyiss_modal_like_a_boss
       awwyiss_modal_nice_one]
  end

  # Return the name of a random awwyiss modal template
  def random_awwyiss_modal
    awwyiss_modal_templates = meme_modal_list

    template = awwyiss_modal_templates[rand(awwyiss_modal_templates.length)]
    if awwyiss_modal_templates.length <= 3 || current_user.awwyiss_history.length < 3
      current_user.awwyiss_history.shift if current_user.awwyiss_history.length > 2
      current_user.awwyiss_history << template
      # Don't run validations here since we may be reloading the tasks view to
      # show validation errors on tasks:
      current_user.save(validate: false)
      return template
    end

    # Ensure we aren't repeating one of the last 3 awwyiss templates the user
    # has seen:
    while current_user.awwyiss_history.include?(template)
      template = awwyiss_modal_templates[rand(awwyiss_modal_templates.length)]
    end
    current_user.awwyiss_history.shift
    current_user.awwyiss_history << template
    # Don't run validations here since we may be reloading the tasks view to
    # show validation errors on tasks:
    current_user.save(validate: false)
    template
  end
end
