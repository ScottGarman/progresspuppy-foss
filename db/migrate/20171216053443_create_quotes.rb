class CreateQuotes < ActiveRecord::Migration[5.1]
  def up
    create_table :quotes do |t|
      t.string  :quotation, null: false
      t.string  :source,    null: false
      t.integer :user_id,   null: false

      t.timestamps
    end
  end

  def down
    drop_table :quotes
  end
end
