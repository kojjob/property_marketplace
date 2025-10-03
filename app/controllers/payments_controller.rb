class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking, only: [ :new, :create, :process_payment ]
  before_action :ensure_tenant, only: [ :new, :create, :process_payment ]

  def new
    @payment = @booking.payments.build
    @client_secret = create_payment_intent
  end

  def create
    service = BookingPaymentService.new(@booking, payment_params)

    result = service.call

    if result.success?
      redirect_to @booking, notice: "Payment processed successfully!"
    else
      @client_secret = create_payment_intent
      @error = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def process_payment
    # This action handles the AJAX payment processing
    service = BookingPaymentService.new(@booking, payment_params)

    result = service.call

    if result.success?
      render json: { success: true, payment: result.data[:payment] }, status: :ok
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end

  private

  def set_booking
    @booking = Booking.find(params[:booking_id])
  end

  def ensure_tenant
    unless @booking.tenant == current_user
      redirect_to @booking, alert: "You are not authorized to make payments for this booking."
    end
  end

  def payment_params
    params.require(:payment).permit(:amount_cents, :payment_method_id, :currency)
  end

  def create_payment_intent
    # In a real implementation, this would create a Stripe PaymentIntent
    # For now, return a mock client secret for testing
    "pi_mock_client_secret"
  end
end
