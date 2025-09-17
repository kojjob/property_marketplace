class Webhooks::StripeController < ApplicationController
  # Skip CSRF protection for webhooks
  protect_from_forgery except: :create

  # Skip authentication for webhooks
  skip_before_action :authenticate_user!

  def create
    payload = request.body.read
    signature = request.headers["Stripe-Signature"]

    begin
      # Verify webhook signature
      event = Stripe::Webhook.construct_event(
        payload,
        signature,
        Rails.application.credentials.stripe&.webhook_secret || ENV["STRIPE_WEBHOOK_SECRET"]
      )

      # Process the event
      case event["type"]
      when "payment_intent.succeeded"
        handle_payment_succeeded(event)
      when "payment_intent.payment_failed"
        handle_payment_failed(event)
      when "invoice.payment_succeeded"
        handle_subscription_payment_succeeded(event)
      when "customer.subscription.deleted"
        handle_subscription_cancelled(event)
      else
        # Unhandled event type
        render json: { status: "ignored", message: "Unhandled event type: #{event['type']}" }, status: :ok
        return
      end

      render json: { status: "success" }, status: :ok

    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature: #{e.message}" }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error "Webhook error: #{e.message}"
      render json: { error: "Webhook processing failed: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def handle_payment_succeeded(event)
    payment_intent = event["data"]["object"]
    transaction_reference = payment_intent["id"]

    # Find and update payment record
    payment = Payment.find_by(transaction_reference: transaction_reference)
    if payment
      payment.update!(
        status: "completed",
        processed_at: Time.current
      )

      # Update booking payment status
      update_booking_payment_status(payment.booking)
    end
  end

  def handle_payment_failed(event)
    payment_intent = event["data"]["object"]
    transaction_reference = payment_intent["id"]
    error_message = payment_intent.dig("last_payment_error", "message") || "Payment failed"

    # Find and update payment record
    payment = Payment.find_by(transaction_reference: transaction_reference)
    if payment
      payment.update!(
        status: "failed",
        failure_reason: error_message
      )
    end
  end

  def handle_subscription_payment_succeeded(event)
    invoice = event["data"]["object"]
    subscription_id = invoice["subscription"]
    invoice_id = invoice["id"]
    amount_paid = invoice["amount_paid"] / 100.0 # Convert from cents
    booking_id = invoice.dig("metadata", "booking_id")

    # Create recurring payment record
    if booking_id && (booking = Booking.find_by(id: booking_id))
      Payment.create!(
        booking: booking,
        payer: booking.tenant,
        payee: booking.landlord,
        amount: amount_paid,
        transaction_reference: invoice_id,
        payment_method: "stripe",
        payment_type: "subscription",
        status: "completed",
        processed_at: Time.current
      )
    end
  end

  def handle_subscription_cancelled(event)
    subscription = event["data"]["object"]
    subscription_id = subscription["id"]
    booking_id = subscription.dig("metadata", "booking_id")

    # Update any related booking or subscription records
    # This could involve creating a cancellation payment record or updating booking status
    Rails.logger.info "Subscription cancelled: #{subscription_id} for booking: #{booking_id}"
  end

  def update_booking_payment_status(booking)
    total_paid = Payment.where(booking: booking, status: "completed").sum(:amount)

    if total_paid >= booking.total_amount
      booking.update!(payment_status: "paid")
    elsif total_paid > 0
      booking.update!(payment_status: "partially_paid")
    end
  end
end
