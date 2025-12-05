class AddAccessLevelToMetadataTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_types, :access_level, :integer, :default => 0
  end
end
