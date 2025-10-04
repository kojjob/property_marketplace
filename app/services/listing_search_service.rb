class ListingSearchService < ApplicationService
  def initialize(search_params)
    @search_params = search_params
    @listings = Listing.available
  end

  def call
    apply_location_filters
    apply_property_filters
    apply_price_filters
    apply_amenity_filters
    apply_availability_filters
    apply_sorting
    apply_pagination

    success(
      listings: @listings,
      total_count: @total_count,
      page: current_page,
      per_page: per_page
    )
  end

  private

  attr_reader :search_params

  def apply_location_filters
    if search_params[:location].present?
      # Simple location search - in production, use geocoding
      @listings = @listings.joins(:property)
                          .where("properties.address ILIKE :location OR properties.city ILIKE :location OR properties.state ILIKE :location",
                                location: "%#{search_params[:location]}%")
    end

    if search_params[:latitude].present? && search_params[:longitude].present?
      # Radius search - requires PostGIS or similar
      # For now, simplified implementation
      @listings = @listings.joins(:property)
                          .where("properties.latitude BETWEEN ? AND ?",
                                search_params[:latitude].to_f - 0.1,
                                search_params[:latitude].to_f + 0.1)
                          .where("properties.longitude BETWEEN ? AND ?",
                                search_params[:longitude].to_f - 0.1,
                                search_params[:longitude].to_f + 0.1)
    end
  end

  def apply_property_filters
    if search_params[:property_type].present?
      @listings = @listings.joins(:property)
                          .where(properties: { property_type: search_params[:property_type] })
    end

    if search_params[:bedrooms_min].present?
      @listings = @listings.joins(:property)
                          .where("properties.bedrooms >= ?", search_params[:bedrooms_min])
    end

    if search_params[:bedrooms_max].present?
      @listings = @listings.joins(:property)
                          .where("properties.bedrooms <= ?", search_params[:bedrooms_max])
    end

    if search_params[:bathrooms_min].present?
      @listings = @listings.joins(:property)
                          .where("properties.bathrooms >= ?", search_params[:bathrooms_min])
    end

    if search_params[:guests].present?
      @listings = @listings.where("max_guests >= ?", search_params[:guests])
    end
  end

  def apply_price_filters
    if search_params[:price_min].present?
      @listings = @listings.where("price_per_night >= ?", search_params[:price_min])
    end

    if search_params[:price_max].present?
      @listings = @listings.where("price_per_night <= ?", search_params[:price_max])
    end
  end

  def apply_amenity_filters
    if search_params[:amenities].present?
      amenities = Array(search_params[:amenities])
      amenities.each do |amenity|
        @listings = @listings.where("amenities ? :amenity", amenity: amenity)
      end
    end
  end

  def apply_availability_filters
    if search_params[:check_in_date].present? && search_params[:check_out_date].present?
      # Find listings without conflicting bookings
      booked_listing_ids = Booking
        .where(status: [ "confirmed", "pending" ])
        .where("(check_in_date <= ? AND check_out_date >= ?) OR (check_in_date <= ? AND check_out_date >= ?)",
               search_params[:check_out_date], search_params[:check_in_date],
               search_params[:check_out_date], search_params[:check_in_date])
        .pluck(:listing_id)

      @listings = @listings.where.not(id: booked_listing_ids)
    end

    if search_params[:instant_book].present?
      @listings = @listings.where(instant_book: true)
    end
  end

  def apply_sorting
    sort_by = search_params[:sort_by] || "relevance"

    @listings = case sort_by
    when "price_low_to_high"
                  @listings.order(price_per_night: :asc)
    when "price_high_to_low"
                  @listings.order(price_per_night: :desc)
    when "rating"
                  @listings.left_joins(:reviews)
                          .group("listings.id")
                          .order("AVG(reviews.rating) DESC NULLS LAST")
    when "newest"
                  @listings.order(created_at: :desc)
    when "relevance"
                  # In production, implement relevance scoring
                  @listings.order(created_at: :desc)
    else
                  @listings
    end
  end

  def apply_pagination
    @total_count = @listings.count
    @listings = @listings.page(current_page).per(per_page)
  end

  def current_page
    (search_params[:page] || 1).to_i
  end

  def per_page
    [ (search_params[:per_page] || 20).to_i, 100 ].min  # Max 100 per page
  end
end
