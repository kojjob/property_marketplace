class PropertyPolicy < ApplicationPolicy
  def index?
    true # Anyone can browse properties
  end

  def show?
    true # Anyone can view property details
  end

  def create?
    user.landlord? || user.agent? || user.admin?
  end

  def update?
    user.admin? || user == record.user
  end

  def destroy?
    user.admin? || user == record.user
  end

  def edit?
    update?
  end

  def manage_images?
    update?
  end

  def publish?
    update? && record.draft?
  end

  def unpublish?
    update? && record.active?
  end

  def feature?
    user.admin? # Only admins can feature properties
  end

  def favorite?
    user.present? # Any authenticated user can favorite properties
  end

  def unfavorite?
    user.present? # Any authenticated user can unfavorite properties
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.landlord? || user&.agent?
        # Landlords and agents can see their own properties and active ones
        scope.where(user: user).or(scope.where(status: "active"))
      else
        # Regular users can only see active properties
        scope.where(status: "active")
      end
    end
  end
end
