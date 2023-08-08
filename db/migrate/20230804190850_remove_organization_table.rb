class RemoveOrganizationTable < ActiveRecord::Migration[7.0]
  def change
    remove_column :copyright_permissions, :organization_id
    drop_table :organizations
  end
end
