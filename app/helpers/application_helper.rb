 module ApplicationHelper
   def safe_url(url)
     return nil if url.blank?

     # Only allow http and https protocols
     begin
       uri = URI.parse(url)
       return url if [ "http", "https" ].include?(uri.scheme)
     rescue URI::InvalidURIError
       return nil
     end

     # If no scheme, assume https
     return "https://#{url}" if url.present?
     nil
   end

   def status_badge_class(status)
     case status
     when "pending"
       "bg-yellow-100 text-yellow-800"
     when "confirmed"
       "bg-green-100 text-green-800"
     when "cancelled"
       "bg-red-100 text-red-800"
     when "completed"
       "bg-blue-100 text-blue-800"
     else
       "bg-gray-100 text-gray-800"
     end
   end

   def payment_status_class(status)
     case status
     when "unpaid"
       "text-red-600"
     when "partially_paid"
       "text-orange-600"
     when "paid"
       "text-green-600"
     else
       "text-gray-600"
     end
   end
 end
