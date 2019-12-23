class TaskCategoriesController < ApplicationController
  before_action :logged_in_user

  def index
    @task_categories = current_user.task_categories
    @new_task_category = TaskCategory.new
  end

  def show
    @task_category = current_user.task_categories.find_by_id(params[:id])
    if @task_category.nil?
      flash[:danger] = 'Task Category not found'
      redirect_to(task_categories_path) && return
    end

    respond_to do |f|
      f.js
    end
  end

  def create
    @new_task_category = current_user.task_categories
                                     .build(task_category_params)
    if @new_task_category.save
      flash[:success] = 'New task category created'
      redirect_to(task_categories_path)
    else
      @task_categories = current_user.task_categories.reload
      render('index')
    end
  end

  def edit
    @task_category = current_user.task_categories.find_by_id(params[:id])
    if @task_category.nil?
      flash[:danger] = 'Task Category not found'
      redirect_to(task_categories_path) && return
    end

    respond_to do |f|
      f.js
    end
  end

  def update
    @task_category = current_user.task_categories.find_by_id(params[:id])
    if @task_category.nil?
      flash[:danger] = 'Update failed: Task Category not found'
      redirect_to(task_categories_path) && return
    end

    if @task_category.name == 'Uncategorized'
      flash[:danger] = 'The Uncategorized task category cannot be renamed'
      redirect_to(task_categories_path) && return
    end

    if @task_category.update(task_category_params)
      flash[:success] = 'Task Category updated'
    end
    redirect_to(task_categories_path)
  end

  def delete_confirmation
    @task_category = current_user.task_categories.find_by_id(params[:id])
    if @task_category.nil?
      flash[:danger] = 'Deleting Task Category failed: category not found'
      redirect_to(task_categories_path) && return
    end

    # Find out how many tasks would be impacted by the deletion
    @num_impacted_tasks = current_user.tasks.where('task_category_id = ?',
                                                   @task_category.id).count

    respond_to do |f|
      f.js
    end
  end

  def destroy
    @task_category = current_user.task_categories.find_by_id(params[:id])
    if @task_category.nil?
      flash[:danger] = 'Deleting Task Category failed: category not found'
      redirect_to(task_categories_path) && return
    end

    if @task_category.name == 'Uncategorized'
      flash[:danger] = 'The Uncategorized task category cannot be deleted'
      redirect_to(task_categories_path) && return
    end

    # Re-assign any existing tasks from this category to Uncategorized
    new_tc = current_user.task_categories.find_by_name('Uncategorized')
    current_user.tasks.category(@task_category).move_to_category(new_tc.id)

    @task_category.destroy
    flash[:success] = 'Task Category deleted'
    redirect_to(task_categories_path)
  end

  private

  def task_category_params
    params.require(:task_category).permit(:name)
  end
end
