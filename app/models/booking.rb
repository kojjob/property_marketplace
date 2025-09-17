class Booking < ApplicationRecord
  belongs_to :listing
  belongs_to :tenant, class_name: 'User', foreign_key: 'tenant_id'
  belongs_to :landlord, class_name: 'User', foreign_key: 'landlord_id'
  has_many :payments, dependent: :destroy

  # Enums
  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }
  enum :payment_status, { unpaid: 0, partially_paid: 1, paid: 2 }, prefix: true

  # Validations
  validates :check_in_date, presence: true
  validates :check_out_date, presence: true
  validate :check_out_after_check_in
  validate :no_overlapping_bookings, on: :create

  # Scopes
  scope :upcoming, -> { where('check_in_date > ?', Date.current) }
  scope :past, -> { where('check_out_date < ?', Date.current) }
  scope :current, -> { where('check_in_date <= ? AND check_out_date >= ?', Date.current, Date.current) }

  # Instance methods
  def total_paid
    payments.successful.sum(:amount) - payments.successful.where(payment_type: 'refund').sum(:amount).abs
  end

  def completed?
    status == 'completed'
  end

  def confirmed?
    status == 'confirmed'
  end

  private

  def check_out_after_check_in
    return unless check_in_date && check_out_date

    if check_out_date <= check_in_date
      errors.add(:check_out_date, "must be after check-in date")
    end
  end

  def no_overlapping_bookings
    return unless listing && check_in_date && check_out_date

    overlapping = listing.bookings
      .where(status: ['pending', 'confirmed'])
      .where.not(id: id)
      .where('(check_in_date <= ? AND check_out_date >= ?) OR (check_in_date <= ? AND check_out_date >= ?)',
             check_out_date, check_in_date, check_out_date, check_in_date)

    if overlapping.exists?
      errors.add(:base, "These dates overlap with an existing booking")
    end
  end
end