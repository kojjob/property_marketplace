class ContactController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_params)

    if @contact_message.save
      # Send email notification (we'll implement this later with ActionMailer)
      flash[:notice] = "Thank you for your message! We'll get back to you soon."
      redirect_to contact_path
    else
      flash.now[:alert] = "Please correct the errors below."
      render :index, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.require(:contact_message).permit(:name, :email, :phone, :subject, :message)
  end
end
