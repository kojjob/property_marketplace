class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  # Enums
  enum :role, { tenant: 0, landlord: 1, agent: 2, admin: 3 }
  enum :verification_status, { unverified: 0, pending: 1, verified: 2 }

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
end
