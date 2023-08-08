class AddOrganizationToCopyrightPermission < ActiveRecord::Migration[7.0]
  def change
    add_column :copyright_permissions, :organization_name, :string
    add_column :copyright_permissions, :organization_website, :string
    add_column :copyright_permissions, :organization_contact_information, :string
    remove_reference :organizations, :copyright_permissions
  end
end
