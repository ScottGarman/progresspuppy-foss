class CreateUsers < ActiveRecord::Migration[5.1]
  def up
    create_table :users do |t|
      t.string   :first_name,      null: false, limit: 50
      t.string   :last_name,       null: false, limit: 50
      t.string   :email,           null: false, limit: 80
      t.string   :password_digest, null: false, limit: 80
      t.boolean  :email_confirmed, default: false
      t.datetime :last_login_at
      t.boolean  :admin, default: false

      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end
