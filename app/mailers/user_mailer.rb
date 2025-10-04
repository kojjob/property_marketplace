class UserMailer < ApplicationMailer
  default from: "Property Marketplace <noreply@propertymarketplace.com>"

  def new_message_notification(message)
    @message = message
    @recipient = message.recipient
    @sender = message.sender
    @conversation = message.conversation

    mail(
      to: @recipient.email,
      subject: "New message from #{@sender.profile&.full_name || @sender.email.split('@').first}"
    )
  end

  def booking_request_notification(booking)
    @booking = booking
    @tenant = booking.tenant
    @landlord = booking.landlord
    @property = booking.listing.property

    mail(
      to: @landlord.email,
      subject: "New booking request for your property"
    )
  end

  def booking_confirmation_notification(booking)
    @booking = booking
    @tenant = booking.tenant
    @landlord = booking.landlord
    @property = booking.listing.property

    mail(
      to: @tenant.email,
      subject: "Booking confirmed for #{property.title}"
    )
  end

  def payment_notification(payment)
    @payment = payment
    @booking = payment.booking
    @property = @booking.listing.property

    mail(
      to: payment.user.email,
      subject: "Payment #{payment.status.titleize} - #{payment.amount.format}"
    )
  end
end
