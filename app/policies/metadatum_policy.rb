class MetadatumPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def edit?
    @user.admin? || @user.editor? || @user.intern?
  end

  def create?
    @user.admin? || @user.editor? || @user.intern?
  end

  def update?
    @user.admin? || @user.editor? || @user.intern?
  end

  def review?
    @user.admin? || @user.editor?
  end

  def destroy?
    @user.admin? || @user.editor?
  end

  def search?
    true
  end
end
