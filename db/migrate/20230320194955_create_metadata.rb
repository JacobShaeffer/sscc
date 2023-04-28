class CreateMetadata < ActiveRecord::Migration[7.0]
  def change
    create_table :metadata do |t|
      t.string :name
      t.references :metadata_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
