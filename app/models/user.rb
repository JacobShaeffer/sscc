class User < ApplicationRecord
  include Ransackable

  RANSACKABLE_ATTRIBUTES = %w[name role].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

		has_many :contents
    has_many :metadata_types
    has_many :metadata

    # define user roles
    enum :role, {guest: 0, organization: 1, volunteer: 2, intern: 3, admin: 99}

    # set default user role
    after_initialize :set_default_role

    validates :name, presence: true

    private

    def set_default_role
      self.role ||= :guest
    end
end
