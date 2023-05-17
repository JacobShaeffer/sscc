class MetadataType < ApplicationRecord
    belongs_to :user
    has_many :metadata, dependent: :destroy

		validates :name, presence: true, uniqueness: true, allow_blank: false
end
