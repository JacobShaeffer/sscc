class AddNeedsReviewToMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata, :needs_review, :boolean, default: true
  end
end
