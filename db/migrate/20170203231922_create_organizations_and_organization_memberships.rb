class CreateOrganizationsAndOrganizationMemberships < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations do |t|
      t.string :name, index: true
      t.string :public_email
      t.string :gravatar_email
      t.string :billing_email
      t.text :description
      t.string :url
      t.string :location

      t.timestamps
    end

    create_table :organization_memberships do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :user, index: true
      t.boolean :admin, index: true, default: false
    end
  end
end
