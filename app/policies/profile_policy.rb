class ProfilePolicy < ApplicationPolicy
  def show?
    true # Public profiles
  end

  def create?
    user == record.user
  end

  def update?
    user.admin? || user == record.user
  end

  def destroy?
    user.admin? && user != record.user
  end

  def edit?
    update?
  end

  def verify?
    user.admin? # Only admins can verify profiles
  end

  def unverify?
    user.admin? # Only admins can unverify profiles
  end

  class Scope < Scope
    def resolve
      scope.all # All profiles are visible
    end
  end
end
