class CopyrightPermissionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true
  end

  def list?
    index?
  end

  def show?
    true
  end

  def create?
    @user.admin? || @user.intern?
  end

  def new?
    create?
  end

  def update?
    @user.admin? || @user.intern?
  end

  def edit?
    update?
  end

  def destroy?
    @user.admin?
  end

  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
end
