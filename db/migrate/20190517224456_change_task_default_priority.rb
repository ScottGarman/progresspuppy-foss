class ChangeTaskDefaultPriority < ActiveRecord::Migration[5.2]
  def change
    change_column_default :tasks, :priority, from: 0, to: 3
  end
end
