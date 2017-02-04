# Creates the groups table and a join table
class CreateGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :groups do |t|
      t.belongs_to :organization, index: true
      t.string :name, index: true
      t.text :description

      t.timestamps
    end

    create_table :groups_users, id: false do |t|
      t.belongs_to :group, index: true
      t.belongs_to :user, index: true
    end
  end
end
