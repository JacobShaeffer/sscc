class ChangeFieldsToFinal < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :display_title, :string
    add_column :contents, :description, :text
    add_column :contents, :year_of_publication, :integer
    add_column :contents, :copyright_notes, :text

    rename_column :organizations, :email, :contact_information

    rename_column :copyright_permissions, :description, :notes
    remove_column :copyright_permissions, :granted
    add_column :copyright_permissions, :granted, :integer
    add_column :copyright_permissions, :communication, :string

    add_column :users, :name, :string
  end
end
