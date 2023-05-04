class AddNullConstraintToMetadata < ActiveRecord::Migration[7.0]
  def change
    change_column_null :metadata, :user_id, false, 1
    change_column_null :metadata_types, :user_id, false, 1
  end
end
