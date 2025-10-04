class ListingPolicy < ApplicationPolicy
  def index?
    true # Anyone can browse listings
  end

  def show?
    true # Anyone can view listing details
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

  def publish?
    update? && record.draft?
  end

  def unpublish?
    update? && record.active?
  end

  def book?
    user.tenant? && record.active? && record.available?
  end

  def instant_book?
    book? && record.instant_book?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.landlord? || user&.agent?
        # Landlords and agents can see their own listings and active ones
        scope.where(user: user).or(scope.where(status: "active"))
      else
        # Regular users can only see active listings
        scope.where(status: "active")
      end
    end
  end
end
