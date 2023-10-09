class Metadatum < ApplicationRecord
  belongs_to :user
  belongs_to :metadata_type
  has_many :content_metadata, dependent: :destroy
  has_many :contents, through: :content_metadata
  
	validates :name, presence: true, allow_blank: false, uniqueness: { scope: :metadata_type_id }
end
