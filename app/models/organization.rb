class Organization < ApplicationRecord
  belongs_to :user
  has_many :copyright_permissions, dependent: :destroy
  validates :user_id, 
    inclusion: { in: -> (uid) {[uid.user_id_was]}, :message => "User_id cannot be changed" }, 
    on: :update
end
