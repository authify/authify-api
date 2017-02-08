# Make it so we can have global admin users
class AddAdminToUser < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.boolean :admin
      t.index :admin
    end
  end
end
