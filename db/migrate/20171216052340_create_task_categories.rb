class CreateTaskCategories < ActiveRecord::Migration[5.1]
  def up
    create_table :task_categories do |t|
      t.string  :name,    null: false
      t.integer :user_id, null: false

      t.timestamps
    end
  end

  def down
    drop_table :task_categories
  end
end
