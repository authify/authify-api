# Adding a unique index to email on users
class AddUniqueIndexToUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :email, unique: true, name: :index_users_unique_on_email
  end
end
