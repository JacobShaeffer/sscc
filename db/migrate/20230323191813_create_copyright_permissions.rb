class CreateCopyrightPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :copyright_permissions do |t|
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.boolean :granted
      t.date :date_contacted
      t.date :date_of_response
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
