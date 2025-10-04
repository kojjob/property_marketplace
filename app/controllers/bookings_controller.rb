class BookingsController < ApplicationController
   before_action :authenticate_user!
   before_action :set_listing, only: [ :new, :create ], if: -> { params[:listing_id].present? }
   before_action :set_booking, only: [ :show, :confirm, :cancel, :edit, :update, :destroy ]
  before_action :ensure_owner_or_tenant, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_landlord, only: [ :confirm ]
  before_action :ensure_tenant, only: [ :cancel ]

  def index
    if @listing
      # Bookings for a specific listing (landlord view)
      ensure_listing_owner
      @bookings = @listing.bookings.includes(:tenant, :property)
    else
      # User's bookings (tenant view)
      @bookings = current_user.bookings_as_tenant.includes(:listing, :property, :landlord)
    end

    @bookings = @bookings.order(created_at: :desc)
  end

  def show
  end

  def new
    @booking = @listing.bookings.build
    @booking.tenant = current_user

    # Set default dates if provided
    @booking.check_in_date = Date.parse(params[:check_in]) if params[:check_in].present?
    @booking.check_out_date = Date.parse(params[:check_out]) if params[:check_out].present?
    @booking.guests_count = params[:guests]&.to_i || 1

    # Calculate total amount
    if @booking.check_in_date && @booking.check_out_date
      @booking.valid? # This triggers the calculation in the model callback
    end
  end

  def create
    @booking = @listing.bookings.build(booking_params)
    @booking.tenant = current_user

    if @booking.save
      # Send confirmation emails
      BookingMailer.confirmation(@booking).deliver_later
      BookingMailer.new_booking_notification(@booking).deliver_later

      redirect_to @booking, notice: "Booking request submitted successfully! You will receive a confirmation email shortly."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @booking.update(booking_params)
      redirect_to @booking, notice: "Booking was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def confirm
    if @booking.confirm!
      redirect_to @booking, notice: "Booking confirmed successfully!"
    else
      redirect_to @booking, alert: "Unable to confirm booking. Please try again."
    end
  end

  def cancel
    cancellation_reason = params[:cancellation_reason]

    if @booking.cancel!(cancellation_reason)
      redirect_to @booking, notice: "Booking cancelled successfully."
    else
      redirect_to @booking, alert: "Unable to cancel booking. Please try again."
    end
  end

  def destroy
    @booking.destroy
    redirect_to bookings_path, notice: "Booking was successfully deleted."
  end

  private

  def set_listing
    @listing = Listing.find(params[:listing_id]) if params[:listing_id]
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def ensure_owner_or_tenant
    unless @booking.tenant == current_user || @booking.landlord == current_user
      redirect_to listings_path, alert: "You are not authorized to view this booking."
    end
  end

  def ensure_landlord
    unless @booking.landlord == current_user
      redirect_to @booking, alert: "Only the property owner can confirm bookings."
    end
  end

  def ensure_tenant
    unless @booking.tenant == current_user
      redirect_to @booking, alert: "Only the tenant can cancel their booking."
    end
  end

  def ensure_listing_owner
    unless @listing.user == current_user
      redirect_to listings_path, alert: "You are not authorized to view these bookings."
    end
  end

  def booking_params
    params.require(:booking).permit(
      :check_in_date, :check_out_date, :guests_count, :special_requests,
      :total_amount, :service_fee, :cancellation_reason
    )
  end
end
