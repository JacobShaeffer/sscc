class AddOrderToMetadataTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_types, :order, :integer
  end
end
