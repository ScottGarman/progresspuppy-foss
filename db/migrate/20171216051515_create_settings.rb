class CreateSettings < ActiveRecord::Migration[5.1]
  def up
    create_table :settings do |t|
      t.boolean :show_quotes, default: true
      t.boolean :burnination, default: false
      t.integer :user_id

      t.timestamps
    end
  end

  def down
    drop_table :settings
  end
end
