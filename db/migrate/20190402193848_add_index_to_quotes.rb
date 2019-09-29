class AddIndexToQuotes < ActiveRecord::Migration[5.2]
  def change
    add_index :quotes, :user_id
  end
end
