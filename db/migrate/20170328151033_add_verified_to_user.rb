# User verifications
class AddVerifiedToUser < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.boolean :verified
      t.string :verification_token
      t.index :verified
    end
  end
end
