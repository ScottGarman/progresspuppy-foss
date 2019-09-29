class AddIndexesToTasks < ActiveRecord::Migration[5.2]
  def change
    add_index :tasks, :user_id
    add_index :tasks, :task_category_id
  end
end
