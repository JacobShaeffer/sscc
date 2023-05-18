class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

		has_many :contents
    has_many :metadata_types
    has_many :metadata

    # define user roles
    enum :role, {guest: 0, organization: 1, volunteer: 2, intern: 3, admin: 99}

    # set default user role
    after_initialize :set_default_role

    private

    def set_default_role
      self.role ||= :user
    end
end
