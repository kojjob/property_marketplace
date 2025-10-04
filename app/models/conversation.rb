class Conversation < ApplicationRecord
  # Associations
  belongs_to :participant1, class_name: "User", foreign_key: "participant1_id"
  belongs_to :participant2, class_name: "User", foreign_key: "participant2_id"
  has_many :messages, dependent: :destroy

  # Validations
  validate :participants_are_different

  # Scopes
  scope :for_user, ->(user_id) {
    where("participant1_id = ? OR participant2_id = ?", user_id, user_id)
  }
  scope :between, ->(user1_id, user2_id) {
    where(
      "(participant1_id = ? AND participant2_id = ?) OR (participant1_id = ? AND participant2_id = ?)",
      user1_id, user2_id, user2_id, user1_id
    )
  }
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :with_messages, -> { joins(:messages).distinct }
  scope :recent, -> { order(last_message_at: :desc) }

  # Class methods
  def self.find_or_create_between(user1, user2)
    return nil if user1 == user2

    conversation = between(user1.id, user2.id).first
    return conversation if conversation

    # Ensure consistent ordering to avoid race conditions
    participant1, participant2 = [ user1, user2 ].sort_by(&:id)
    create!(participant1: participant1, participant2: participant2)
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition where another process created the conversation
    between(user1.id, user2.id).first
  end

  # Instance methods
  def other_participant(user)
    return nil unless user
    participant1_id == user.id ? participant2 : participant1
  end

  def participant?(user)
    return false unless user
    participant1_id == user.id || participant2_id == user.id
  end

  def unread_count_for(user)
    return 0 unless participant?(user)
    messages.unread.where(recipient_id: user.id).count
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def mark_as_read_for(user)
    return unless participant?(user)
    messages.unread.where(recipient_id: user.id).update_all(
      status: Message.statuses[:read],
      read_at: Time.current
    )
  end

  def archive!
    update!(archived: true, archived_at: Time.current)
  end

  def unarchive!
    update!(archived: false, archived_at: nil)
  end

  private

  def participants_are_different
    if participant1_id == participant2_id
      errors.add(:participant2, "can't be the same as participant1")
    end
  end
end
