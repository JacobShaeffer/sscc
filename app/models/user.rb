class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

		has_many :contents

    # define user roles
    enum :role, {user: 0, admin: 99}

    # set default user role
    after_initialize :set_default_role

    private

    def set_default_role
      self.role ||= :user
    end
end
