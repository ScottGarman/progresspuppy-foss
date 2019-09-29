class AddIndexToSettings < ActiveRecord::Migration[5.2]
  def change
    add_index :settings, :user_id
  end
end
