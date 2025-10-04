class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 50, 50 ]
    attachable.variant :small, resize_to_limit: [ 100, 100 ]
    attachable.variant :medium, resize_to_limit: [ 200, 200 ]
  end

  # Declare the attribute for messaging_availability enum
  attribute :messaging_availability, :string, default: "everyone"

  # Enums
  enum :role, { tenant: 0, landlord: 1, agent: 2, admin: 3 }
  enum :verification_status, { unverified: 0, pending: 1, verified: 2 }
  enum :messaging_availability, {
    everyone: "everyone",           # Anyone can message
    verified_only: "verified_only", # Only verified users can message
    connections_only: "connections_only", # Only users with existing conversations
    disabled: "disabled"            # No one can message
  }, prefix: true

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone_number, presence: true
  validates :phone_number, format: {
    with: /\A[\+\d\-\(\)\s\.]+\z/,
    message: "must be a valid phone number"
  }, allow_blank: true

  # Scopes
  scope :verified, -> { where(verification_status: "verified") }
  scope :landlords, -> { where(role: "landlord") }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    if first_name.present? && last_name.present?
      full_name
    else
      user&.email
    end
  end

  def verified?
    verification_status == "verified"
  end

  def can_list_property?
    role.in?([ "landlord", "agent", "admin" ])
  end

  # Messaging preferences
  def accepts_messages?
    allow_messages
  end

  def can_receive_message_from?(sender_user)
    return false unless allow_messages

    case messaging_availability
    when "disabled"
      false
    when "everyone"
      true
    when "verified_only"
      sender_user.profile&.verified? || false
    when "connections_only"
      # Check if there's an existing conversation
      user.conversations.joins(:messages)
          .where("participant1_id = ? OR participant2_id = ?", sender_user.id, sender_user.id)
          .exists?
    else
      true # Default to allowing messages
    end
  end
end
