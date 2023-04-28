class Metadatum < ApplicationRecord
  belongs_to :metadata_type
  has_many :content_metadata, dependent: :destroy
  has_many :contents, through: :content_metadata
end
