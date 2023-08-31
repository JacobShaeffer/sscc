class MetadatumPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def edit?
    @user.admin? || @user.intern?
  end

  def create?
    @user.admin? || @user.intern?
  end

  def update?
    @user.admin? || @user.intern?
  end

  def destroy?
    @user.admin?
  end

  def search?
    true
  end
end
