class AddAcceptedTosAtToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :accepted_tos_at, :datetime
  end
end
