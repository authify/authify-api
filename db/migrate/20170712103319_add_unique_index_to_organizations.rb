# Adding a unique index to name on organizations
class AddUniqueIndexToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_index :organizations, :name, unique: true, name: :index_organizations_unique_on_name
  end
end
