class SearchAlertMailer < ApplicationMailer
  def new_properties_alert(saved_search, new_properties)
    @saved_search = saved_search
    @new_properties = new_properties.first(5) # Limit to 5 properties in email
    @user = saved_search.user

    mail(
      to: @user.email,
      subject: "New Properties Match Your Saved Search: #{saved_search.name}"
    )
  end
end
