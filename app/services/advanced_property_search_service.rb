# frozen_string_literal: true

class AdvancedPropertySearchService < ApplicationService
    attr_reader :params, :user

    def initialize(params = {}, user = nil)
      @params = params.with_indifferent_access
      @user = user
    end

    def call
      validate_params
      return failure("Invalid parameters", errors: @errors) if @errors.present?

      results = perform_search
      save_search if params[:save_search] && user.present?

      success(
        properties: results[:properties],
        listings: results[:listings],
        total_count: results[:total_count],
        page: current_page,
        per_page: per_page_value,
        total_pages: total_pages(results[:properties] || results[:listings]),
        has_next_page: has_next_page?(results[:properties] || results[:listings]),
        has_prev_page: has_prev_page?,
        facets: include_facets? ? build_facets : nil,
        suggestions: (results[:properties] || results[:listings])&.empty? ? build_suggestions : nil,
        search_type: results[:search_type]
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
      suggestions += Property.location_suggestions(params[:query]) if Property.respond_to?(:location_suggestions)

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
      # Determine search type based on parameters
      if params[:search_type] == "listings" || listing_specific_params?
        search_listings
      else
        search_properties
      end
    end

    def search_properties
      scope = Property.includes(:user, :property_images, :listings)

      # Only show active properties unless specified
      scope = scope.where(status: "active") unless params[:include_all_statuses]

      # Text search
      if params[:query].present? || params[:q].present?
        query = params[:query] || params[:q]
        scope = scope.where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
      end

      # Location search
      scope = apply_location_search(scope)

      # Apply filters
      scope = apply_property_filters(scope)

      # Apply sorting
      scope = apply_sorting(scope)

      # Apply pagination
      scope = apply_pagination(scope)

      {
        properties: scope,
        listings: nil,
        total_count: total_count(scope),
        search_type: "properties"
      }
    end

    def search_listings
      scope = Listing.includes(:property, property: :property_images).where(status: "active")

      # Text search through listing and property
      if params[:query].present? || params[:q].present?
        query = params[:query] || params[:q]
        scope = scope.joins(:property)
          .where("listings.title ILIKE ? OR listings.description ILIKE ? OR properties.title ILIKE ? OR properties.description ILIKE ?",
                 "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
      end

      # Location search through property
      scope = apply_listing_location_filters(scope)

      # Apply property filters
      scope = apply_listing_property_filters(scope)

      # Apply price filters
      scope = apply_listing_price_filters(scope)

      # Apply amenity filters
      scope = apply_listing_amenity_filters(scope)

      # Apply availability filters
      scope = apply_listing_availability_filters(scope)

      # Apply sorting
      scope = apply_listing_sorting(scope)

      # Apply pagination
      scope = apply_pagination(scope)

      {
        properties: nil,
        listings: scope,
        total_count: total_count(scope),
        search_type: "listings"
      }
    end

    def listing_specific_params?
      params[:check_in_date].present? ||
        params[:check_out_date].present? ||
        params[:instant_book].present? ||
        params[:max_guests].present?
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
        scope = scope.where("address ILIKE ? OR city ILIKE ? OR region ILIKE ?",
                           "%#{address}%", "%#{address}%", "%#{address}%")
      elsif (params[:latitude] || params[:lat]).present? && (params[:longitude] || params[:lng]).present?
        # Coordinate-based search - simplified for now
        lat = params[:latitude] || params[:lat]
        lng = params[:longitude] || params[:lng]
        scope = scope.where("latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?",
                           lat.to_f - 0.1, lat.to_f + 0.1,
                           lng.to_f - 0.1, lng.to_f + 0.1)
      end

      scope
    end

    def apply_property_filters(scope)
      filters = params[:filters] || params

      # Price filters
      if filters[:min_price].present? || filters[:max_price].present?
        scope = scope.where(price: filters[:min_price]..filters[:max_price])
      end

      # Bedroom filters
      if filters[:bedrooms].present?
        if filters[:bedrooms].is_a?(Hash)
          scope = scope.where("bedrooms >= ?", filters[:bedrooms][:min])
        else
          scope = scope.where(bedrooms: filters[:bedrooms])
        end
      end

      # Bathroom filters
      if filters[:bathrooms].present?
        if filters[:bathrooms].is_a?(Hash)
          scope = scope.where("bathrooms >= ?", filters[:bathrooms][:min])
        else
          scope = scope.where(bathrooms: filters[:bathrooms])
        end
      end

      # Property type filter
      if filters[:property_type].present?
        scope = scope.where(property_type: filters[:property_type])
      end

      # Square feet filter
      if filters[:min_sqft].present? || filters[:max_sqft].present?
        scope = scope.where(square_feet: filters[:min_sqft]..filters[:max_sqft])
      end

      scope
    end

    def apply_listing_location_filters(scope)
      if params[:location].present?
        scope = scope.joins(:property)
          .where("properties.address ILIKE ? OR properties.city ILIKE ? OR properties.region ILIKE ?",
                 "%#{params[:location]}%", "%#{params[:location]}%", "%#{params[:location]}%")
      end

      if params[:latitude].present? && params[:longitude].present?
        # Radius search - simplified implementation
        scope = scope.joins(:property)
          .where("properties.latitude BETWEEN ? AND ?",
                 params[:latitude].to_f - 0.1,
                 params[:latitude].to_f + 0.1)
          .where("properties.longitude BETWEEN ? AND ?",
                 params[:longitude].to_f - 0.1,
                 params[:longitude].to_f + 0.1)
      end

      scope
    end

    def apply_listing_property_filters(scope)
      if params[:property_type].present?
        scope = scope.joins(:property)
          .where(properties: { property_type: params[:property_type] })
      end

      if params[:bedrooms_min].present?
        scope = scope.joins(:property)
          .where("properties.bedrooms >= ?", params[:bedrooms_min])
      end

      if params[:bedrooms_max].present?
        scope = scope.joins(:property)
          .where("properties.bedrooms <= ?", params[:bedrooms_max])
      end

      if params[:bathrooms_min].present?
        scope = scope.joins(:property)
          .where("properties.bathrooms >= ?", params[:bathrooms_min])
      end

      if params[:max_guests].present?
        scope = scope.where("max_guests >= ?", params[:max_guests])
      end

      scope
    end

    def apply_listing_price_filters(scope)
      if params[:price_min].present?
        scope = scope.where("price >= ?", params[:price_min])
      end

      if params[:price_max].present?
        scope = scope.where("price <= ?", params[:price_max])
      end

      scope
    end

    def apply_listing_amenity_filters(scope)
      if params[:amenities].present?
        amenities = Array(params[:amenities])
        amenities.each do |amenity|
          scope = scope.where("amenities ? :amenity", amenity: amenity)
        end
      end

      scope
    end

    def apply_listing_availability_filters(scope)
      if params[:check_in_date].present? && params[:check_out_date].present?
        # Find listings without conflicting bookings
        booked_listing_ids = Booking
          .where(status: [ "confirmed", "pending" ])
          .where("(check_in_date <= ? AND check_out_date >= ?) OR (check_in_date <= ? AND check_out_date >= ?)",
                 params[:check_out_date], params[:check_in_date],
                 params[:check_out_date], params[:check_in_date])
          .pluck(:listing_id)

        scope = scope.where.not(id: booked_listing_ids)
      end

      if params[:instant_book].present?
        scope = scope.where(instant_book: true)
      end

      scope
    end

    def apply_sorting(scope)
      sort_by = params[:sort_by] || params[:sort]

      case sort_by
      when "price_asc"
        scope.order(price: :asc)
      when "price_desc"
        scope.order(price: :desc)
      when "newest"
        scope.order(created_at: :desc)
      when "largest"
        scope.order(square_feet: :desc)
      when "distance"
        # Distance sorting is automatic when using near scope
        scope
      else
        scope.order(created_at: :desc)
      end
    end

    def apply_listing_sorting(scope)
      sort_by = params[:sort_by] || "relevance"

      case sort_by
      when "price_low_to_high"
        scope.order(price: :asc)
      when "price_high_to_low"
        scope.order(price: :desc)
      when "rating"
        scope.left_joins(:reviews)
          .group("listings.id")
          .order("AVG(reviews.rating) DESC NULLS LAST")
      when "newest"
        scope.order(created_at: :desc)
      else
        scope.order(created_at: :desc)
      end
    end

    def apply_pagination(scope)
      if defined?(Kaminari) && !params[:skip_pagination]
        scope.page(current_page).per(per_page_value)
      else
        offset = (current_page - 1) * per_page_value
        scope.offset(offset).limit(per_page_value)
      end
    end

    def validate_params
      @errors = []

      # Validate price
      if params[:min_price].present? && !valid_number?(params[:min_price])
        @errors << "Invalid minimum price format"
      end

      if params[:max_price].present? && !valid_number?(params[:max_price])
        @errors << "Invalid maximum price format"
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

      # Validate date ranges for bookings
      if params[:check_in_date].present? && params[:check_out_date].present?
        begin
          check_in = Date.parse(params[:check_in_date])
          check_out = Date.parse(params[:check_out_date])
          if check_in >= check_out
            @errors << "Check-out date must be after check-in date"
          end
        rescue ArgumentError
          @errors << "Invalid date format"
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
      return unless user.present?

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
        :bedrooms, :bathrooms, :property_type, :min_sqft, :max_sqft,
        :check_in_date, :check_out_date, :search_type
      )
    end

    def build_facets
      base_scope = Property.where(status: "active")

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
      scope.group(:city, :region)
        .count
        .transform_keys { |city, region| "#{city}, #{region}" }
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

    def current_page
      (params[:page] || 1).to_i
    end

    def per_page_value
      value = (params[:per_page] || 20).to_i
      value > 100 ? 100 : value # Limit to 100 items per page
    end

    def total_count(scope)
      return 0 if scope.nil?

      if scope.respond_to?(:total_count)
        scope.total_count # Kaminari
      elsif scope.respond_to?(:total_entries)
        scope.total_entries # Will Paginate
      elsif scope.is_a?(ActiveRecord::Relation)
        scope.except(:limit, :offset).count
      else
        scope.count
      end
    end

    def total_pages(scope)
      return 1 if scope.nil?

      if scope.respond_to?(:total_pages)
        scope.total_pages
      else
        (total_count(scope).to_f / per_page_value).ceil
      end
    end

    def has_next_page?(scope)
      return false if scope.nil?
      current_page < total_pages(scope)
    end

    def has_prev_page?
      current_page > 1
    end

    def include_facets?
      params[:include_facets].present? && params[:include_facets] != "false"
    end
end
