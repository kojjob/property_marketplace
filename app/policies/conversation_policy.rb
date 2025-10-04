class ConversationPolicy < ApplicationPolicy
  def index?
    true # Users can see their own conversations
  end

  def show?
    user == record.sender || user == record.recipient
  end

  def create?
    true # Anyone can start a conversation
  end

  def update?
    user == record.sender || user == record.recipient
  end

  def destroy?
    user.admin? || user == record.sender || user == record.recipient
  end

  class Scope < Scope
    def resolve
      scope.where(sender: user).or(scope.where(recipient: user))
    end
  end
end
