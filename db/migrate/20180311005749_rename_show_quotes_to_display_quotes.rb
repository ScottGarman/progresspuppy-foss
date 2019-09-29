class RenameShowQuotesToDisplayQuotes < ActiveRecord::Migration[5.1]
  def change
    rename_column :settings, :show_quotes, :display_quotes
  end
end
