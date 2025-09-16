class Payment < ApplicationRecord
  # Associations
  belongs_to :booking
  belongs_to :payer, class_name: 'User', foreign_key: 'payer_id'
  belongs_to :payee, class_name: 'User', foreign_key: 'payee_id'

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :payment_type, presence: true
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code" }

  # Custom validations
  validate :payer_and_payee_different
  validate :amount_matches_booking, on: :create
  validate :no_duplicate_payment, on: :create
  validate :booking_status_appropriate
  validate :valid_currency_code
  validate :service_fee_not_negative
  validate :valid_status_transition, if: :status_changed?
  validate :refund_amount_valid, if: -> { payment_type == 'refund' }

  # Callbacks
  before_validation :set_default_currency
  before_validation :upcase_currency
  before_validation :round_amounts
  before_create :generate_transaction_id
  after_commit :update_booking_payment_status, on: [:create, :update]

  # Enums
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    refunded: 4,
    cancelled: 5
  }

  enum :payment_type, {
    deposit: 0,
    full_payment: 1,
    final_payment: 2,
    refund: 3,
    security_deposit: 4,
    additional_fee: 5
  }

  enum :payment_method, {
    credit_card: 0,
    debit_card: 1,
    bank_transfer: 2,
    paypal: 3,
    stripe: 4,
    cash: 5,
    other: 6
  }

  # Scopes
  scope :successful, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { where('payments.created_at > ?', 30.days.ago) }
  scope :for_booking, ->(booking_id) { where(booking_id: booking_id) }

  # Class methods
  def self.total_for_booking(booking_id)
    for_booking(booking_id).successful.sum(:amount)
  end

  # Instance methods
  def process_payment!
    return false if status != 'pending' && status != 'processing'

    update!(status: 'processing') if status == 'pending'

    if charge_payment_method
      update!(status: 'completed', processed_at: Time.current)
      true
    else
      update!(status: 'failed')
      false
    end
  rescue StandardError => e
    update!(status: 'failed', failure_reason: e.message)
    false
  end

  def refundable?
    status == 'completed'
  end

  def process_refund!(refund_amount = nil)
    raise StandardError, "Payment cannot be refunded" unless refundable?

    refund_amount ||= amount
    raise StandardError, "Refund amount must be greater than 0" if refund_amount <= 0
    raise StandardError, "Refund amount cannot exceed payment amount" if refund_amount > amount

    # Check if total refunds would exceed original amount
    existing_refunds = Payment.where(
      booking: booking,
      payment_type: 'refund',
      status: 'completed'
    ).sum(:amount).abs

    if existing_refunds + refund_amount > amount
      raise StandardError, "Refund amount exceeds remaining refundable amount"
    end

    refund = Payment.create!(
      booking: booking,
      payer: payee,  # Refund goes from payee back to payer
      payee: payer,
      amount: refund_amount,
      payment_type: 'refund',
      status: 'completed',
      currency: currency,
      payment_method: payment_method,
      processed_at: Time.current
    )

    # Mark original payment as refunded if full refund
    update!(status: 'refunded', refunded_at: Time.current) if refund_amount == amount

    refund
  end

  def net_amount
    return amount unless service_fee
    amount - service_fee
  end

  def formatted_amount
    symbol = case currency
             when 'USD' then '$'
             when 'EUR' then '€'
             when 'GBP' then '£'
             when 'JPY' then '¥'
             when 'CNY' then '¥'
             else currency + ' '
             end

    formatted_value = '%.2f' % amount
    parts = formatted_value.split('.')
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
    "#{symbol}#{parts.join('.')}"
  end

  def total_refunded
    Payment.where(
      booking: booking,
      payment_type: 'refund',
      status: 'completed'
    ).where('created_at > ?', created_at).sum(:amount)
  end

  private

  def set_default_currency
    self.currency ||= 'USD'
  end

  def upcase_currency
    self.currency = currency&.upcase
  end

  def round_amounts
    self.amount = amount&.round(2) if amount
    self.service_fee = service_fee&.round(2) if service_fee
  end

  def generate_transaction_id
    return if transaction_id.present?

    loop do
      self.transaction_id = "PAY-#{SecureRandom.alphanumeric(10).upcase}"
      break unless Payment.exists?(transaction_id: transaction_id)
    end
  end

  def charge_payment_method
    # Simulate payment processing
    # In real implementation, this would integrate with payment gateway
    return true if payment_method == 'cash'

    # Simulate success rate for testing
    rand > 0.1  # 90% success rate
  end

  def payer_and_payee_different
    return unless payer_id.present? && payee_id.present?
    return unless payer_id == payee_id

    errors.add(:payee, "can't be the same as payer")
  end

  def amount_matches_booking
    return unless booking && payment_type == 'full_payment' && amount.present?

    if amount != booking.total_amount
      errors.add(:amount, "must match booking total for full payment")
    end
  end

  def no_duplicate_payment
    return unless booking && payment_type == 'full_payment'

    existing = Payment.where(
      booking: booking,
      payment_type: 'full_payment'
    ).where.not(id: id)

    if existing.exists?
      errors.add(:booking, "already has a full payment")
    end
  end

  def booking_status_appropriate
    return unless booking
    return if persisted? # Skip for existing records

    unless booking.confirmed? || booking.completed?
      errors.add(:booking, "must be confirmed or completed for payment")
    end
  end

  def valid_currency_code
    return unless currency

    valid_codes = %w[USD EUR GBP JPY CNY AUD CAD CHF SEK NOK DKK PLN CZK HUF]
    unless valid_codes.include?(currency)
      errors.add(:currency, "is not a valid currency")
    end
  end

  def service_fee_not_negative
    return unless service_fee

    if service_fee < 0
      errors.add(:service_fee, "cannot be negative")
    end
  end

  def valid_status_transition
    return unless status_changed? && status_was.present?

    invalid_transitions = {
      'cancelled' => ['completed'],
      'refunded' => ['pending', 'processing'],
      'failed' => ['refunded']
    }

    if invalid_transitions[status_was]&.include?(status)
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end

  def refund_amount_valid
    # Refunds should have positive amounts like other payments
    # The refund nature is tracked by payment_type, not negative amount
    return unless payment_type == 'refund' && amount

    if amount <= 0
      errors.add(:amount, "must be positive for refunds")
    end
  end

  def update_booking_payment_status
    return unless booking && status == 'completed'

    total_paid = Payment.for_booking(booking.id).successful.sum(:amount)

    if total_paid >= booking.total_amount
      booking.update_column(:payment_status, 'paid')
    elsif total_paid > 0
      booking.update_column(:payment_status, 'partially_paid')
    end
  end
end