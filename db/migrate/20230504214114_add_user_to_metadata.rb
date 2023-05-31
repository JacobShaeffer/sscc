class AddUserToMetadata < ActiveRecord::Migration[7.0]
  def change
    add_reference :metadata, :user, foreign_key: true
    add_reference :metadata_types, :user, foreign_key: true
  end
end
