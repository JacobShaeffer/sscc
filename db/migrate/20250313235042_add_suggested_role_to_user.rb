class AddSuggestedRoleToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :suggested_role, :integer
  end
end
