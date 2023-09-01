class Content < ApplicationRecord
  belongs_to :user
  belongs_to :copyright_permission
  has_many :content_metadata, dependent: :destroy
  has_many :metadata, through: :content_metadata

  has_one_attached :file

  validates :title, presence: true, allow_blank: false
  validates :display_title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :file, presence: true, allow_blank: false
end