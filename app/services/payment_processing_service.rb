class PaymentProcessingService < ApplicationService
  def initialize(booking, payment_params)
    @booking = booking
    @payment_params = payment_params
  end

  def call
    ActiveRecord::Base.transaction do
      validate_booking_status
      validate_payment_amount
      create_payment
      process_payment_with_gateway
      update_booking_status
      send_receipts
      success(payment: @payment)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  rescue StandardError => e
    handle_payment_failure(e)
    failure(e.message)
  end

  private

  attr_reader :booking, :payment_params

  def validate_booking_status
    unless booking.status == "confirmed" || booking.status == "pending"
      raise StandardError, "Booking must be confirmed or pending for payment"
    end
  end

  def validate_payment_amount
    if payment_params[:payment_type] == "full_payment"
      unless payment_params[:amount].to_f == booking.total_amount
        raise StandardError, "Full payment amount must match booking total"
      end
    elsif payment_params[:payment_type] == "deposit"
      min_deposit = booking.total_amount * 0.2  # 20% minimum deposit
      unless payment_params[:amount].to_f >= min_deposit
        raise StandardError, "Deposit must be at least 20% of total amount"
      end
    end
  end

  def create_payment
    @payment = Payment.new(
      booking: booking,
      payer: payment_params[:payer] || booking.tenant,
      payee: booking.listing.user,
      amount: payment_params[:amount],
      payment_type: payment_params[:payment_type],
      payment_method: payment_params[:payment_method],
      status: "pending",
      currency: payment_params[:currency] || "USD"
    )

    # Calculate service fee (3% platform fee)
    @payment.service_fee = @payment.amount * 0.03
    @payment.save!
  end

  def process_payment_with_gateway
    # In a real app, this would integrate with Stripe, PayPal, etc.
    # For now, we'll simulate payment processing
    result = simulate_payment_processing

    if result[:success]
      @payment.update!(
        status: "completed",
        processed_at: Time.current,
        transaction_reference: result[:transaction_id]
      )
    else
      raise StandardError, result[:error_message]
    end
  end

  def simulate_payment_processing
    # Simulate payment gateway response
    if rand > 0.05  # 95% success rate
      {
        success: true,
        transaction_id: "TXN-#{SecureRandom.hex(10).upcase}"
      }
    else
      {
        success: false,
        error_message: "Payment declined by bank"
      }
    end
  end

  def update_booking_status
    if @payment.payment_type == "full_payment" && @payment.status == "completed"
      booking.update!(payment_status: "paid", status: "confirmed")
    elsif @payment.payment_type == "deposit" && @payment.status == "completed"
      booking.update!(payment_status: "partially_paid", status: "confirmed")
    end
  end

  def send_receipts
    # Queue receipt emails using Solid Queue
    PaymentReceiptJob.perform_later(@payment) if defined?(PaymentReceiptJob)
  end

  def handle_payment_failure(error)
    @payment&.update!(
      status: "failed",
      failure_reason: error.message
    )
  end
end
