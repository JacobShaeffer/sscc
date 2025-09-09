class MetadatumPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def edit?
    @user.admin? || @user.intern_plus? || @user.intern?
  end

  def create?
    @user.admin? || @user.intern_plus? || @user.intern?
  end

  def update?
    @user.admin? || @user.intern_plus? || @user.intern?
  end

  def review?
    @user.admin? || @user.intern_plus?
  end

  def destroy?
    @user.admin? || @user.intern_plus?
  end

  def search?
    true
  end
end
