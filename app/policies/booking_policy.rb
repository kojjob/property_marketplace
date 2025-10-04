class BookingPolicy < ApplicationPolicy
  def index?
    user.admin? || user == record.tenant || user == record.landlord
  end

  def show?
    user.admin? || user == record.tenant || user == record.landlord
  end

  def create?
    user.tenant? && record.nil? # Can create bookings if they're a tenant
  end

  def update?
    user.admin? || user == record.landlord
  end

  def destroy?
    user.admin? || user == record.tenant || user == record.landlord
  end

  def cancel?
    user.admin? ||
    (user == record.tenant && record.pending?) ||
    (user == record.landlord && record.pending?)
  end

  def confirm?
    user.admin? || user == record.landlord
  end

  def reject?
    user.admin? || user == record.landlord
  end

  def complete?
    user.admin? || user == record.landlord
  end

  def review?
    user == record.tenant && record.completed?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.where(landlord: user)
      elsif user.tenant?
        scope.where(tenant: user)
      else
        scope.none
      end
    end
  end
end
