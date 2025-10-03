class Comment < ApplicationRecord
  belongs_to :blog_post
  belongs_to :parent, class_name: "Comment", optional: true
  belongs_to :user, optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  # Validations
  validates :content, presence: true, length: { maximum: 2000 }
  validates :author_name, presence: true, unless: :user?
  validates :author_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :user?
  validates :status, inclusion: { in: %w[pending approved rejected] }

  # Callbacks
  before_validation :set_default_status, on: :create
  after_save :approve_reply_if_parent_approved

  # Scopes
  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def user?
    user.present?
  end

  def guest?
    !user?
  end

  def approved?
    status == "approved"
  end

  def pending?
    status == "pending"
  end

  def rejected?
    status == "rejected"
  end

  def approve!
    update(status: "approved", approved_at: Time.current)
  end

  def reject!
    update(status: "rejected")
  end

  def author_display_name
    user? ? user.profile.first_name : author_name
  end

  def author_email_address
    user? ? user.email : author_email
  end

  def root_comment?
    parent_id.nil?
  end

  def reply?
    !root_comment?
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def approve_reply_if_parent_approved
    nil unless saved_change_to_status? && approved? && reply?

    # If this reply is approved and it's a reply to an approved comment,
    # we might want to auto-approve it, but for now we'll keep it manual
  end
end
