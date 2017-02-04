class CreateTrustedDelegates < ActiveRecord::Migration[5.0]
  def change
    create_table :trusted_delegates do |t|
      t.string :name, index: true
      t.string :access_key, index: true
      t.text :secret_key_digest
      t.text :description

      t.timestamps
    end
  end
end
