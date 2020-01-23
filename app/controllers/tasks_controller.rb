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
    if @task.nil?
      flash[:danger] = 'Task not found'
      redirect_to_correct_tasks_tab && return
    end

    respond_to do |f|
      f.js
    end
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
      @quote = random_quote
      @awwyiss_modal = random_awwyiss_modal
      render_correct_tasks_tab
    end
  end

  def edit
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Task not found'
      redirect_to_correct_tasks_tab && return
    end

    respond_to do |f|
      f.js
    end
  end

  def update
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Updating task failed: task not found'
      redirect_to_correct_tasks_tab && return
    end

    if @task.update(task_params)
      flash[:success] = task_change_flash_msg(@task, params[:tasks_view],
                                              'Task updated')
    end
    redirect_to_correct_tasks_tab
  end

  def destroy
    @task = current_user.tasks.find_by(id: params[:id])
    if @task.nil?
      flash[:danger] = 'Deleting task failed: task not found'
      redirect_to_correct_tasks_tab && return
    end

    @task.destroy
    flash[:success] = 'Task deleted'
    redirect_to_correct_tasks_tab
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

    respond_to do |f|
      f.js
    end
  end

  def advance_overdue_tasks
    num_overdue_tasks = current_user.tasks.overdue(today_db).count
    current_user.tasks.current_with_due_dates(today_db).update(due_at: today_db)
    @current_tasks = current_user.tasks.current(today_db)
                                 .paginate(page: params[:page], per_page: 20)
    flash[:success] = "Updated #{num_overdue_tasks} task due" \
                      " #{'date'.pluralize(num_overdue_tasks)} to today"
    redirect_to tasks_path(page: params[:page])
  end

  def search
    @quote = random_quote
    @awwyiss_modal = random_awwyiss_modal

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
    when 'index'
      view = 'index'
    when 'upcoming'
      view = 'upcoming'
    when 'search'
      view = 'search'
    else
      view = 'index'
    end

    render(view)
  end

  def random_quote
    # Use pluck to only get the ids from the quotes table and not load
    # all of the entries into memory:
    quote_ids = current_user.quotes.pluck(:id)
    return nil if quote_ids.empty?

    # Use sample to return a random id from the array:
    current_user.quotes.find(quote_ids.sample)
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

    awwyiss_modal_templates[rand(awwyiss_modal_templates.length)]
  end
end
