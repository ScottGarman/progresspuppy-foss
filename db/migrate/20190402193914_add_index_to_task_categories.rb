class AddIndexToTaskCategories < ActiveRecord::Migration[5.2]
  def change
    add_index :task_categories, :user_id
  end
end
