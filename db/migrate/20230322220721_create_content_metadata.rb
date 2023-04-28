class CreateContentMetadata < ActiveRecord::Migration[7.0]
  def change
    create_table :content_metadata do |t|

      t.integer :content_id
      t.integer :metadatum_id

      t.timestamps
    end
  end
end
