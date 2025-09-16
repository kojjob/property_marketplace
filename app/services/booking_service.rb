class BookingService < ApplicationService
  def initialize(listing, tenant, booking_params)
    @listing = listing
    @tenant = tenant
    @booking_params = booking_params
  end

  def call
    ActiveRecord::Base.transaction do
      validate_availability
      validate_tenant_verification
      create_booking
      send_notifications
      success(booking: @booking)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  rescue StandardError => e
    failure(e.message)
  end

  private

  attr_reader :listing, :tenant, :booking_params

  def validate_availability
    overlapping = Booking.where(listing: listing, status: ['confirmed', 'pending'])
                         .where('(check_in_date <= ? AND check_out_date >= ?) OR (check_in_date <= ? AND check_out_date >= ?)',
                                booking_params[:check_out_date], booking_params[:check_in_date],
                                booking_params[:check_out_date], booking_params[:check_in_date])

    if overlapping.exists?
      raise StandardError, "These dates are not available"
    end
  end

  def validate_tenant_verification
    unless tenant.identity_verified?
      raise StandardError, "Tenant must be identity verified to book"
    end
  end

  def create_booking
    @booking = Booking.create!(
      listing: listing,
      tenant: tenant,
      check_in_date: booking_params[:check_in_date],
      check_out_date: booking_params[:check_out_date],
      total_amount: calculate_total_amount,
      status: 'pending'
    )
  end

  def calculate_total_amount
    nights = (booking_params[:check_out_date].to_date - booking_params[:check_in_date].to_date).to_i
    listing.price_per_night * nights
  end

  def send_notifications
    # Queue notification jobs using Solid Queue
    BookingNotificationJob.perform_later(@booking, 'created') if defined?(BookingNotificationJob)
  end
end