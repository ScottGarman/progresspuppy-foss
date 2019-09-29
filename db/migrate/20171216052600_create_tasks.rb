class CreateTasks < ActiveRecord::Migration[5.1]
  def up
    create_table :tasks do |t|
      t.string   :summary, null: false
      t.integer  :task_category_id
      t.integer  :priority, default: 0, null: false
      t.string   :status, default: 'INCOMPLETE', null: false
      t.date     :due_at
      t.datetime :completed_at
      t.integer  :user_id, null: false

      t.timestamps
    end
  end

  def down
    drop_table :tasks
  end
end
