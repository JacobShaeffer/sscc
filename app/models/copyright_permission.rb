class CopyrightPermission < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  has_many :content

  validates :organization_id, presence: true
  validates :granted, presence: true
  validates :date_contacted, presence: true
  validates :date_of_response, presence: true
  validates :communication, presence: true, allow_blank: false
end
