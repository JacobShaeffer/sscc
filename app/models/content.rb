class Content < ApplicationRecord
  belongs_to :user
  belongs_to :copyright_permission
  mount_uploader :file, FileUploader
  serialize :file, JSON # If useing SQLite, add this line.
  has_many :content_metadata, dependent: :destroy
  has_many :metadata, through: :content_metadata

  validates :title, presence: true, allow_blank: false
  validates :display_title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :file, presence: true, allow_blank: false
  validates :copyright_permission, presence: true, allow_blank: false
end