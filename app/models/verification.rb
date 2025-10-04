class Verification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  # Active Storage
  has_many_attached :documents

  # Validations
  validates :verification_type, presence: true
  validates :status, presence: true
  validate :document_required_for_type

  # Enums
  enum :verification_type, {
    email: 0,
    phone: 1,
    identity: 2,
    address: 3,
    background_check: 4,
    income: 5
  }

  enum :status, {
    pending: 0,
    in_review: 1,
    approved: 2,
    rejected: 3,
    expired: 4
  }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :active, -> { where.not(status: "expired") }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  # Callbacks
  before_create :set_expiry_date
  before_save :check_expiry

  # Instance methods
  def approve!(admin)
    transaction do
      update!(
        status: "approved",
        verified_by: admin,
        verified_at: Time.current
      )

      # Trigger notification
      notify_user("approved")
    end
  end

  def reject!(admin, reason)
    transaction do
      update!(
        status: "rejected",
        verified_by: admin,
        verified_at: Time.current,
        rejection_reason: reason
      )

      # Trigger notification
      notify_user("rejected")
    end
  end

  def expire!
    update!(
      status: "expired",
      expired_at: Time.current
    )
  end

  def can_be_reviewed?
    status.in?([ "pending", "in_review" ])
  end

  def requires_document?
    verification_type.in?([ "identity", "address", "background_check", "income" ])
  end

  def check_expiry
    if expires_at && expires_at < Time.current && status != "expired"
      self.status = "expired"
      self.expired_at = Time.current
    end
  end

  private

  def document_required_for_type
    if requires_document? && document_url.blank?
      errors.add(:document_url, "is required for #{verification_type} verification")
    end
  end

  def set_expiry_date
    self.expires_at = case verification_type
    when "email", "phone"
                        7.days.from_now
    when "identity", "background_check"
                        1.year.from_now
    when "address", "income"
                        6.months.from_now
    else
                        30.days.from_now
    end
  end

  def notify_user(action)
    # In a real app, this would enqueue a job with Solid Queue
    VerificationNotificationJob.perform_later(self, action) if defined?(VerificationNotificationJob)
  end
end
