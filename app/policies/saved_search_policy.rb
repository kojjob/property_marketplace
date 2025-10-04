class SavedSearchPolicy < ApplicationPolicy
  def index?
    user == record.user
  end

  def show?
    user == record.user
  end

  def create?
    user == record.user
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end

  def execute?
    user == record.user
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
