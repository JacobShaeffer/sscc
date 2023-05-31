class CopyrightPermission < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  has_many :content

  mount_uploader :communication, CommunicationUploader
  serialize :communication, JSON # If useing SQLite, add this line.

  enum granted: {yes: 1, no: 0, pending: 2, more_information_needed: 3}, _prefix: true

  validates :granted, presence: true
  validates :date_contacted, presence: true
  validates :communication, presence: true, allow_blank: false

  def organization_name
    organization.name
  end
end
