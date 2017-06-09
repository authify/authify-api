# Tracking JWT refreshes for some semblence of security
class AddTokenRefreshesToUsers < ActiveRecord::Migration[5.1]
  def change
    change_table :users do |t|
      t.integer :token_refreshes, default: 0, null: false
      t.index :token_refreshes
    end
  end
end
