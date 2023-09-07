class ChangeCopyrightNotesToAdditionalNotes < ActiveRecord::Migration[7.0]
  def change
    rename_column :contents, :copyright_notes, :additional_notes
  end
end
