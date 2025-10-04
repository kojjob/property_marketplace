class ReviewPolicy < ApplicationPolicy
  def index?
    true # Anyone can view reviews
  end

  def show?
    true # Anyone can view individual reviews
  end

  def create?
    user == record.reviewer && record.booking.completed?
  end

  def update?
    user == record.reviewer && record.created_at > 24.hours.ago
  end

  def destroy?
    user.admin? || (user == record.reviewer && record.created_at > 24.hours.ago)
  end

  def moderate?
    user.admin? # Only admins can moderate reviews
  end

  class Scope < Scope
    def resolve
      scope.where(published: true) # Only show published reviews
    end
  end
end
