class RemoveFileFromContents < ActiveRecord::Migration[7.0]
  def change
    remove_column :contents, :file
  end
end
