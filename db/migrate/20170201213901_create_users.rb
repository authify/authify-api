# Creates the users table
class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email, index: true
      t.text :password_digest
      t.string :full_name

      t.timestamps
    end
  end
end
