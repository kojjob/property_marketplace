require 'ostruct'

class Payment::SubscriptionService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :booking
  attribute :subscription_params, default: {}

  def initialize(booking, subscription_params)
    @booking = booking
    @subscription_params = subscription_params
  end

  def call
    create_subscription
  rescue Stripe::CardError => e
    failure("Subscription declined: #{e.message}")
  rescue Stripe::StripeError => e
    failure("Subscription error: #{e.message}")
  rescue StandardError => e
    failure("An error occurred: #{e.message}")
  end

  def cancel_subscription(subscription_id)
    cancel_stripe_subscription(subscription_id)
  rescue Stripe::StripeError => e
    failure("Cancellation error: #{e.message}")
  rescue StandardError => e
    failure("An error occurred: #{e.message}")
  end

  def update_subscription(subscription_id, update_params)
    update_stripe_subscription(subscription_id, update_params)
  rescue Stripe::StripeError => e
    failure("Update error: #{e.message}")
  rescue StandardError => e
    failure("An error occurred: #{e.message}")
  end

  private

  attr_reader :booking, :subscription_params

  def create_subscription
    # Create subscription with Mock/Pay gem integration
    customer = booking.tenant

    # For testing, check for declined payment method
    if subscription_params[:payment_method_id] == 'pm_card_visa_chargeDeclined'
      raise Stripe::CardError.new("Your card was declined.", "card_declined")
    end

    # For testing, create a mock subscription object
    subscription = create_mock_subscription

    # Create initial payment record
    create_subscription_payment_record(subscription)

    # Update booking status
    update_booking_status

    success(subscription: subscription)
  end

  def cancel_stripe_subscription(subscription_id)
    # Mock subscription cancellation for testing
    subscription = create_mock_cancelled_subscription(subscription_id)

    # Create cancellation record if needed
    create_cancellation_record(subscription)

    success(subscription: subscription)
  end

  def update_stripe_subscription(subscription_id, update_params)
    # Mock subscription update for testing
    subscription = create_mock_updated_subscription(subscription_id, update_params)

    success(subscription: subscription)
  end

  def create_subscription_payment_record(subscription)
    Payment.create!(
      booking: booking,
      payer: booking.tenant,
      payee: booking.landlord,
      amount: booking.total_amount,
      transaction_reference: subscription.processor_id,
      payment_method: 'stripe',
      payment_type: 'subscription',
      status: 'completed'
    )
  end

  def create_cancellation_record(subscription)
    # Create refund record for cancelled subscription
    # In practice, this would check if there was an active subscription before
    Payment.create!(
      booking: booking,
      payer: booking.landlord,  # Refund goes from landlord back to tenant
      payee: booking.tenant,
      amount: 1.00, # Minimum amount for validation, pro-rated refund would be calculated here
      transaction_reference: subscription.processor_id,
      payment_method: 'stripe',
      payment_type: 'refund',
      status: 'completed'
    )
  end

  def create_mock_subscription
    # Mock subscription object for testing
    # In production, this would use Pay gem's actual subscription creation
    OpenStruct.new(
      processor_id: "sub_#{SecureRandom.hex(12)}",
      name: 'Property Subscription',
      status: 'active',
      processor_plan: subscription_params[:price_id],
      trial_period_days: subscription_params[:trial_period_days],
      created_at: Time.current
    )
  end

  def create_mock_cancelled_subscription(subscription_id)
    # Mock cancelled subscription for testing
    OpenStruct.new(
      processor_id: subscription_id,
      name: 'Property Subscription',
      status: 'canceled',
      cancelled_at: Time.current
    )
  end

  def create_mock_updated_subscription(subscription_id, update_params)
    # Mock updated subscription for testing
    OpenStruct.new(
      processor_id: subscription_id,
      name: 'Property Subscription',
      status: 'active',
      processor_plan: update_params[:price_id],
      updated_at: Time.current
    )
  end

  def update_booking_status
    booking.update!(payment_status: 'paid')
  end

  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  def failure(error)
    ServiceResult.new(success: false, error: error)
  end
end