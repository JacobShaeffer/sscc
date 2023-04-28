class AddFileToContents < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :file, :string
  end
end
