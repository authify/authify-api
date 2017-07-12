# User handle
class AddHandleToUser < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :handle, :string
    add_index :users, :handle, unique: true
  end

  def down
    remove_index :users, :handle
    remove_column :users, :handle
  end
end
