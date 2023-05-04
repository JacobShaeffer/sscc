class MetadataType < ApplicationRecord
    belongs_to :user
    has_many :metadata, dependent: :destroy
end
