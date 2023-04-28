class AddCopyrightPermissionToContent < ActiveRecord::Migration[7.0]
  def change
    add_reference :contents, :copyright_permission, foreign_key: true
  end
end
