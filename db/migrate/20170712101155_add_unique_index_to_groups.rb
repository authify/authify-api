# Adds a unique index on the group name and org
class AddUniqueIndexToGroups < ActiveRecord::Migration[5.1]
  def change
    add_index :groups, %i[name organization_id], unique: true
  end
end
