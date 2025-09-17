class Message < ApplicationRecord
  # Associations
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :recipient, class_name: "User", foreign_key: "recipient_id"
  belongs_to :conversation
  belongs_to :regarding, polymorphic: true, optional: true

  # Active Storage
  has_many_attached :images
  has_many_attached :documents

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 5000 }
  validate :sender_and_recipient_different
  validate :users_in_conversation

  # Enums
  enum :status, {
    unread: 0,
    read: 1,
    archived: 2,
    deleted: 3
  }

  enum :message_type, {
    text: 0,
    booking_request: 1,
    booking_confirmation: 2,
    booking_cancellation: 3,
    payment_notification: 4,
    system_message: 5
  }

  # Scopes
  scope :unread, -> { where(status: "unread") }
  scope :read, -> { where(status: "read") }
  scope :not_deleted, -> { where.not(status: "deleted") }
  scope :recent, -> { where("messages.created_at > ?", 30.days.ago) }
  scope :for_user, ->(user_id) {
    where("sender_id = ? OR recipient_id = ?", user_id, user_id)
  }
  scope :in_conversation, ->(conversation_id) {
    where(conversation_id: conversation_id)
  }

  # Callbacks
  after_create :update_conversation_last_message
  after_create :notify_recipient

  # Instance methods
  def mark_as_read!
    return if read?
    update!(status: "read", read_at: Time.current)
  end

  def mark_as_unread!
    update!(status: "unread", read_at: nil)
  end

  def archive!
    update!(status: "archived")
  end

  def unarchive!
    update!(status: "read")
  end

  def soft_delete!
    update!(status: "deleted")
  end

  def unread?
    status == "unread"
  end

  def read?
    status == "read"
  end

  private

  def sender_and_recipient_different
    if sender_id == recipient_id
      errors.add(:recipient, "can't send message to yourself")
    end
  end

  def users_in_conversation
    return unless conversation

    unless conversation.participant?(sender)
      errors.add(:sender, "must be part of the conversation")
    end

    unless conversation.participant?(recipient)
      errors.add(:recipient, "must be part of the conversation")
    end
  end

  def update_conversation_last_message
    conversation.update!(last_message_at: created_at)
  end

  def notify_recipient
    return if message_type == "system_message"

    # In a real app, this would enqueue a job with Solid Queue
    # For now, we'll simulate with a job class that would be created later
    MessageNotificationJob.perform_later(self) if defined?(MessageNotificationJob)
  end
end
