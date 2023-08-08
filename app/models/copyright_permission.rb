class CopyrightPermission < ApplicationRecord
  belongs_to :user
  has_many :content

  mount_uploader :communication, CommunicationUploader
  serialize :communication, JSON # If useing SQLite, add this line.

  enum granted: {yes: 1, no: 0, waiting_for_response: 2, organization_requesting_more_information: 3}, _prefix: true

  validates :granted, presence: true
  validates :date_contacted, presence: true
  validates :communication, presence: true, allow_blank: false
  validates :organization_name, presence: true, allow_blank: false
  validates :organization_contact_information, presence: true, allow_blank: false

end
