class User < ApplicationRecord
  include Pay::Billable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # Associations
  has_many :payments, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_properties, through: :favorites, source: :property
  has_one :profile, dependent: :destroy
  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :received_reviews, as: :reviewable, class_name: "Review", dependent: :destroy
  has_many :verifications, dependent: :destroy
  has_many :blog_posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  # Messaging associations
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: "recipient_id", dependent: :destroy
  has_many :conversations_as_participant1, class_name: "Conversation", foreign_key: "participant1_id", dependent: :destroy
  has_many :conversations_as_participant2, class_name: "Conversation", foreign_key: "participant2_id", dependent: :destroy
  has_many :sessions, dependent: :destroy

  # Callbacks
  # after_create :create_profile # Removed - handled in factories

  # Verification helper methods
  def identity_verified?
    verifications.where(verification_type: "identity", status: "approved").exists?
  end

  def email_verified?
    verifications.where(verification_type: "email", status: "approved").exists?
  end

  def phone_verified?
    verifications.where(verification_type: "phone", status: "approved").exists?
  end

  def address_verified?
    verifications.where(verification_type: "address", status: "approved").exists?
  end

  def background_check_verified?
    verifications.where(verification_type: "background_check", status: "approved").exists?
  end

  def income_verified?
    verifications.where(verification_type: "income", status: "approved").exists?
  end

  def fully_verified?
    identity_verified? && email_verified? && phone_verified?
  end

  # Get or create profile
  def profile_or_build
    profile || build_profile
  end

  # Admin check
  def admin?
    profile&.admin?
  end

  # Messaging methods
  def conversations
    Conversation.for_user(id)
  end

  def unread_messages_count
    received_messages.unread.count
  end

  def conversation_with(other_user)
    Conversation.between(id, other_user.id).first
  end

  def can_message?(other_user)
    return false if other_user == self
    return false unless other_user.is_a?(User)

    # Check if the recipient accepts messages
    other_profile = other_user.profile
    return false unless other_profile

    # Check messaging preferences
    other_profile.can_receive_message_from?(self)
  end

  private

  def create_profile
    build_profile(first_name: email.split("@").first.capitalize) unless profile.present?
  end
end
