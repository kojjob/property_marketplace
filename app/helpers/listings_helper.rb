module ListingsHelper
  def listing_type_badge_color(listing_type)
    case listing_type
    when 'rent'
      'success'
    when 'sale'
      'primary'
    when 'short_term'
      'warning'
    when 'subscription'
      'info'
    else
      'secondary'
    end
  end

  def price_period(listing)
    case listing.listing_type
    when 'rent'
      case listing.lease_duration_unit
      when 'days'
        'day'
      when 'weeks'
        'week'
      when 'months'
        'month'
      when 'years'
        'year'
      else
        'month'
      end
    when 'short_term'
      'night'
    when 'subscription'
      'month'
    when 'sale'
      ''
    else
      'month'
    end
  end

  def format_listing_price(listing)
    price = number_with_delimiter(listing.price)
    period = price_period(listing)

    if period.present?
      "$#{price}/#{period}"
    else
      "$#{price}"
    end
  end

  def listing_status_badge_color(status)
    case status
    when 'active'
      'success'
    when 'inactive'
      'warning'
    when 'draft'
      'secondary'
    when 'archived'
      'dark'
    else
      'secondary'
    end
  end

  def amenity_icon(amenity)
    case amenity.name.downcase
    when 'wifi', 'internet'
      'fas fa-wifi'
    when 'parking'
      'fas fa-parking'
    when 'pool', 'swimming pool'
      'fas fa-swimmer'
    when 'gym', 'fitness'
      'fas fa-dumbbell'
    when 'air conditioning', 'ac'
      'fas fa-snowflake'
    when 'heating'
      'fas fa-fire'
    when 'kitchen'
      'fas fa-utensils'
    when 'laundry', 'washer', 'dryer'
      'fas fa-tshirt'
    when 'pets allowed'
      'fas fa-dog'
    when 'smoking allowed'
      'fas fa-smoking'
    when 'balcony', 'terrace'
      'fas fa-building'
    when 'garden'
      'fas fa-tree'
    when 'security'
      'fas fa-shield-alt'
    when 'elevator'
      'fas fa-elevator'
    else
      'fas fa-check'
    end
  end
end