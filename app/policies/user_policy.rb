class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin? || user == record
  end

  def create?
    true # Anyone can create an account
  end

  def update?
    user.admin? || user == record
  end

  def destroy?
    user.admin? && user != record # Admins can't delete themselves
  end

  def edit_profile?
    user == record
  end

  def view_profile?
    true # Public profiles
  end

  def create_saved_search?
    true # Any authenticated user can save searches
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id) # Users can only see themselves
      end
    end
  end
end
