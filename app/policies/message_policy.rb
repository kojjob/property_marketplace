class MessagePolicy < ApplicationPolicy
  def show?
    user == record.sender || user == record.conversation.participants.include?(user)
  end

  def create?
    user == record.sender && record.conversation.participants.include?(user)
  end

  def update?
    user == record.sender && record.created_at > 15.minutes.ago
  end

  def destroy?
    user.admin? || (user == record.sender && record.created_at > 15.minutes.ago)
  end

  class Scope < Scope
    def resolve
      scope.joins(:conversation)
           .where(conversations: { sender: user })
           .or(scope.joins(:conversation)
                   .where(conversations: { recipient: user }))
    end
  end
end
