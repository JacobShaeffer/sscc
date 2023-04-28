class MetadataType < ApplicationRecord
    has_many :metadata, dependent: :destroy
end
