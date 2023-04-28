class CopyrightPermission < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  has_many :content
end
