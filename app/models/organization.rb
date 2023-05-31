class Organization < ApplicationRecord
  belongs_to :user
  has_many :copyright_permissions, dependent: :destroy

  validates :name, presence: true, allow_blank: false
  validates :website, presence: true, allow_blank: false
  validates :contact_information, presence: true, allow_blank: false
end
