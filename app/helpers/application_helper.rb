module ApplicationHelper
  def safe_url(url)
    return nil if url.blank?

    # Only allow http and https protocols
    begin
      uri = URI.parse(url)
      return url if ['http', 'https'].include?(uri.scheme)
    rescue URI::InvalidURIError
      return nil
    end

    # If no scheme, assume https
    return "https://#{url}" if url.present?
    nil
  end
end
