# User handle
class AddHandleToUser < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.string :handle
      t.index :handle
    end
  end
end
