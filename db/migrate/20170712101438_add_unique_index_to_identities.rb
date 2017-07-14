# Adding a unique index to identities on uid and provider
class AddUniqueIndexToIdentities < ActiveRecord::Migration[5.1]
  def change
    add_index :identities, %i[uid provider], unique: true
  end
end
