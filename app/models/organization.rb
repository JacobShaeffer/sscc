class Organization < ApplicationRecord
  belongs_to :user
  has_many :copyright_permissions, dependent: :destroy

  validates :organization, presence: true, allow_blank: false
  validates :granted, presence: true, allow_blank: false
  validates :date_contacted, presence: true, allow_blank: false
  validates :communication, presence: true, allow_blank: false
end
