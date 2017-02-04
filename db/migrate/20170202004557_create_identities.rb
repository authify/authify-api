# Creates the identities table
class CreateIdentities < ActiveRecord::Migration[5.0]
  def change
    create_table :identities do |t|
      t.references :user, index: true
      t.string :provider, index: true
      t.string :uid, index: true

      t.timestamps
    end
  end
end
