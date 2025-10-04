class PropertySearchService < ApplicationService
  attr_reader :params, :user

  def initialize(params = {}, user = nil)
    @params = params.with_indifferent_access
    @user = user
  end

  def call
    validate_params
    return failure("Invalid parameters", errors: @errors) if @errors.present?

    properties = perform_search
    save_search if params[:save_search] && user.present?

    success(
      properties: properties,
      total_count: total_count(properties),
      page: current_page,
      per_page: per_page_value,
      total_pages: total_pages(properties),
      has_next_page: has_next_page?(properties),
      has_prev_page: has_prev_page?,
      facets: include_facets? ? build_facets : nil,
      suggestions: properties.empty? ? build_suggestions : nil
    )
  rescue => e
    Rails.logger.error "PropertySearchService error: #{e.message}"
    failure("Search failed", error: e.message)
  end

  def suggestions
    return [] unless params[:query].present?

    suggestions = []

    # Property title suggestions
    suggestions += Property.active
      .where("title ILIKE ?", "%#{params[:query]}%")
      .limit(5)
      .pluck(:title)

    # Location suggestions
    suggestions += Property.location_suggestions(params[:query])

    # Common search terms
    suggestions << params[:query].pluralize if params[:query].singularize != params[:query]
    suggestions << "luxury #{params[:query]}" if params[:query].match?(/apartment|condo|house/i)

    suggestions.uniq.first(10)
  end

  def related_properties
    return Property.none unless params[:property_id].present?

    property = Property.find_by(id: params[:property_id])
    return Property.none unless property

    # Find similar properties
    related = Property.active
      .where.not(id: property.id)
      .where(property_type: property.property_type)

    # Prioritize properties in same city
    if property.city.present?
      related = related.where(city: property.city)
        .or(related.where("price BETWEEN ? AND ?",
                         property.price * 0.8,
                         property.price * 1.2))
    end

    related.limit(6)
  end

  private

  def perform_search
    # Start with base query
    scope = Property.includes(:user, :property_images)

    # Only show active properties unless specified
    scope = scope.active unless params[:include_all_statuses]

    # Text search
    if params[:query].present? || params[:q].present?
      query = params[:query] || params[:q]
      scope = scope.search_by_text(query)
    end

    # Location search
    scope = apply_location_search(scope)

    # Apply filters
    scope = apply_filters(scope)

    # Apply sorting
    scope = apply_sorting(scope)

    # Apply pagination if using Kaminari
    if defined?(Kaminari) && !params[:skip_pagination]
      scope = scope.page(current_page).per(per_page_value)
    elsif !params[:skip_pagination]
      # Manual pagination
      offset = (current_page - 1) * per_page_value
      scope = scope.offset(offset).limit(per_page_value)
    end

    # Cache if requested
    if params[:use_cache]
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) { scope.to_a }
    else
      scope
    end
  end

  def apply_location_search(scope)
    if params[:bounds].present?
      # Map viewport search
      bounds = params[:bounds]
      scope = scope.where(
        latitude: bounds[:south].to_f..bounds[:north].to_f,
        longitude: bounds[:west].to_f..bounds[:east].to_f
      )
    elsif params[:location].present? || params[:address].present?
      # Address-based search
      address = params[:location] || params[:address]
      radius = params[:radius] || 25
      scope = scope.near(address, radius)
    elsif (params[:latitude] || params[:lat]).present? && (params[:longitude] || params[:lng]).present?
      # Coordinate-based search
      lat = params[:latitude] || params[:lat]
      lng = params[:longitude] || params[:lng]
      radius = params[:radius] || 25
      scope = scope.near([ lat.to_f, lng.to_f ], radius)
    end

    scope
  end

  def apply_filters(scope)
    filters = params[:filters] || params

    # Price filters
    if filters[:min_price].present? || filters[:max_price].present?
      scope = scope.price_between(filters[:min_price], filters[:max_price])
    end

    # Bedroom filters
    if filters[:bedrooms].present?
      if filters[:bedrooms].is_a?(Hash)
        scope = scope.min_bedrooms(filters[:bedrooms][:min])
      else
        scope = scope.by_bedrooms(filters[:bedrooms])
      end
    end

    # Bathroom filters
    if filters[:bathrooms].present?
      if filters[:bathrooms].is_a?(Hash)
        scope = scope.min_bathrooms(filters[:bathrooms][:min])
      else
        scope = scope.by_bathrooms(filters[:bathrooms])
      end
    end

    # Property type filter
    if filters[:property_type].present?
      scope = scope.filter_by_property_type(filters[:property_type])
    end

    # Square feet filter
    if filters[:min_sqft].present? || filters[:max_sqft].present?
      scope = scope.by_square_feet(filters[:min_sqft], filters[:max_sqft])
    end

    scope
  end

  def apply_sorting(scope)
    sort_by = params[:sort_by] || params[:sort]

    case sort_by
    when "price_asc"
      scope.price_low_to_high
    when "price_desc"
      scope.price_high_to_low
    when "newest"
      scope.newest_first
    when "largest"
      scope.largest_first
    when "distance"
      # Distance sorting is automatic when using near scope
      scope
    else
      scope.newest_first
    end
  end

  def validate_params
    @errors = []

    # Validate price
    if params[:min_price].present? && !valid_number?(params[:min_price])
      @errors << "Invalid price format"
    end

    if params[:max_price].present? && !valid_number?(params[:max_price])
      @errors << "Invalid price format"
    end

    # Validate coordinates
    if params[:latitude].present? && !valid_coordinate?(params[:latitude], :latitude)
      @errors << "Invalid latitude"
    end

    if params[:longitude].present? && !valid_coordinate?(params[:longitude], :longitude)
      @errors << "Invalid longitude"
    end

    # Validate bounds
    if params[:bounds].present?
      bounds = params[:bounds]
      unless bounds[:north] && bounds[:south] && bounds[:east] && bounds[:west]
        @errors << "Invalid bounds parameters"
      end
    end
  end

  def valid_number?(value)
    Float(value) rescue false
  end

  def valid_coordinate?(value, type)
    coord = Float(value) rescue false
    return false unless coord

    if type == :latitude
      coord >= -90 && coord <= 90
    else # longitude
      coord >= -180 && coord <= 180
    end
  end

  def save_search
    SavedSearch.create!(
      user: user,
      name: params[:search_name] || "Search from #{Date.current}",
      criteria: search_criteria,
      frequency: params[:alert_frequency] || 0
    )
  rescue => e
    Rails.logger.error "Failed to save search: #{e.message}"
  end

  def search_criteria
    params.slice(
      :query, :q, :location, :address, :latitude, :longitude,
      :lat, :lng, :radius, :min_price, :max_price,
      :bedrooms, :bathrooms, :property_type, :min_sqft, :max_sqft
    )
  end

  def build_facets
    base_scope = Property.active

    {
      property_types: build_property_type_facets(base_scope),
      price_ranges: build_price_range_facets(base_scope),
      bedroom_counts: build_bedroom_facets(base_scope),
      locations: build_location_facets(base_scope)
    }
  end

  def build_property_type_facets(scope)
    scope.group(:property_type).count
  end

  def build_price_range_facets(scope)
    ranges = {
      "0-500000" => scope.where(price: 0..500000).count,
      "500000-1000000" => scope.where(price: 500000..1000000).count,
      "1000000-2000000" => scope.where(price: 1000000..2000000).count,
      "2000000+" => scope.where("price >= ?", 2000000).count
    }
    ranges.select { |_, count| count > 0 }
  end

  def build_bedroom_facets(scope)
    {
      "1" => scope.where(bedrooms: 1).count,
      "2" => scope.where(bedrooms: 2).count,
      "3" => scope.where(bedrooms: 3).count,
      "4" => scope.where(bedrooms: 4).count,
      "5+" => scope.where("bedrooms >= ?", 5).count
    }.select { |_, count| count > 0 }
  end

  def build_location_facets(scope)
    scope.group(:city, :state)
      .count
      .transform_keys { |city, state| "#{city}, #{state}" }
      .sort_by { |_, count| -count }
      .first(10)
      .to_h
  end

  def build_suggestions
    suggestions = [ "Try broadening your search criteria" ]

    if params[:min_price].present? || params[:max_price].present?
      suggestions << "Try adjusting your price range"
    end

    if params[:location].present? || params[:radius].present?
      suggestions << "Try expanding your search radius"
    end

    if params[:property_type].present?
      suggestions << "Try searching for different property types"
    end

    suggestions
  end

  def cache_key
    Digest::SHA256.hexdigest(params.to_json)
  end

  def current_page
    (params[:page] || 1).to_i
  end

  def per_page_value
    value = (params[:per_page] || 20).to_i
    value > 100 ? 100 : value # Limit to 100 items per page
  end

  def total_count(properties)
    if properties.respond_to?(:total_count)
      properties.total_count # Kaminari
    elsif properties.respond_to?(:total_entries)
      properties.total_entries # Will Paginate
    elsif properties.is_a?(ActiveRecord::Relation)
      properties.except(:limit, :offset).count
    else
      properties.count
    end
  end

  def total_pages(properties)
    if properties.respond_to?(:total_pages)
      properties.total_pages
    else
      (total_count(properties).to_f / per_page_value).ceil
    end
  end

  def has_next_page?(properties)
    current_page < total_pages(properties)
  end

  def has_prev_page?
    current_page > 1
  end

  def include_facets?
    params[:include_facets].present? && params[:include_facets] != "false"
  end
end
