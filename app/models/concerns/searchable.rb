module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    # Full-text search configuration
    pg_search_scope :search_by_text,
      against: {
        title: 'A',
        description: 'B',
        address: 'C',
        city: 'C',
        region: 'D'
      },
      using: {
        tsearch: {
          prefix: true,
          dictionary: 'english',
          any_word: true
        }
      }

    # Geocoding for location-based search
    geocoded_by :full_address
    after_validation :geocode, if: :should_geocode?

    # Scopes for filtering
    scope :active, -> { where(status: 'active') }
    scope :by_property_type, ->(type) { where(property_type: type) if type.present? }
    scope :by_bedrooms, ->(count) { where(bedrooms: count) if count.present? }
    scope :min_bedrooms, ->(count) { where('bedrooms >= ?', count) if count.present? }
    scope :by_bathrooms, ->(count) { where(bathrooms: count) if count.present? }
    scope :min_bathrooms, ->(count) { where('bathrooms >= ?', count) if count.present? }
    scope :price_between, ->(min, max) {
      query = all
      query = query.where('price >= ?', min) if min.present?
      query = query.where('price <= ?', max) if max.present?
      query
    }
    scope :by_square_feet, ->(min, max) {
      query = all
      query = query.where('square_feet >= ?', min) if min.present?
      query = query.where('square_feet <= ?', max) if max.present?
      query
    }

    # Sorting scopes
    scope :newest_first, -> { order(created_at: :desc) }
    scope :price_low_to_high, -> { order(price: :asc) }
    scope :price_high_to_low, -> { order(price: :desc) }
    scope :largest_first, -> { order(square_feet: :desc) }
  end

  class_methods do
    # Complex search with multiple filters
    def advanced_search(params = {})
      results = active

      # Text search
      if params[:query].present?
        results = results.search_by_text(params[:query])
      end

      # Location-based search
      if params[:location].present? || (params[:latitude].present? && params[:longitude].present?)
        if params[:location].present?
          # Search by address string
          results = results.near(params[:location], params[:radius] || 25)
        else
          # Search by coordinates
          results = results.near([params[:latitude], params[:longitude]], params[:radius] || 25)
        end
      end

      # Bounds search (for map viewport)
      if params[:bounds].present?
        bounds = params[:bounds]
        results = results.where(
          latitude: bounds[:south]..bounds[:north],
          longitude: bounds[:west]..bounds[:east]
        )
      end

      # Apply filters
      filters = params[:filters] || params
      results = apply_filters(results, filters)

      # Sorting
      results = apply_sorting(results, params[:sort_by] || params[:sort])

      # Pagination (manual implementation without Kaminari)
      if params[:page].present?
        page = params[:page].to_i
        per_page = (params[:per_page] || 20).to_i
        offset = (page - 1) * per_page
        results = results.limit(per_page).offset(offset)
      end

      results
    end

    # Filter properties by price
    def filter_by_price(params)
      price_between(params[:min] || params[:min_price], params[:max] || params[:max_price])
    end

    # Filter by bedrooms
    def filter_by_bedrooms(count_or_params)
      if count_or_params.is_a?(Hash)
        min_bedrooms(count_or_params[:min])
      else
        by_bedrooms(count_or_params)
      end
    end

    # Filter by bathrooms
    def filter_by_bathrooms(params)
      if params.is_a?(Hash)
        min_bathrooms(params[:min])
      else
        by_bathrooms(params)
      end
    end

    # Filter by property type
    def filter_by_property_type(types)
      if types.is_a?(Array)
        where(property_type: types)
      else
        by_property_type(types)
      end
    end

    # Location-based search
    def near_location(params)
      if params[:address].present?
        near(params[:address], params[:radius] || 25)
      elsif params[:latitude].present? && params[:longitude].present?
        near([params[:latitude], params[:longitude]], params[:radius] || 25)
      else
        all
      end
    end

    # Apply multiple filters
    def apply_filters(scope, filters)
      scope = scope.filter_by_price(filters)
      scope = scope.filter_by_bedrooms(filters[:bedrooms]) if filters[:bedrooms].present?
      scope = scope.filter_by_bathrooms(filters[:bathrooms]) if filters[:bathrooms].present?
      scope = scope.filter_by_property_type(filters[:property_type]) if filters[:property_type].present?
      scope = scope.by_square_feet(filters[:min_sqft], filters[:max_sqft])
      scope
    end

    # Apply sorting
    def apply_sorting(scope, sort_by)
      case sort_by
      when 'price_asc'
        scope.price_low_to_high
      when 'price_desc'
        scope.price_high_to_low
      when 'newest'
        scope.newest_first
      when 'largest'
        scope.largest_first
      else
        scope.newest_first
      end
    end

    # Location suggestions for autocomplete
    def location_suggestions(query)
      select(:city, :region)
        .distinct
        .where('city ILIKE ?', "%#{query}%")
        .limit(10)
        .map { |p| "#{p.city}, #{p.region}" }
    end

    # Popular search terms (stub for now - would need a SearchTerm model)
    def popular_search_terms
      # This would typically query a SearchTerm model
      # For now, return empty array
      []
    end

    # Record search term (stub for now)
    def record_search_term(term)
      # This would typically create a SearchTerm record
      # For now, do nothing
      true
    end
  end

  # Instance methods
  def full_address
    [address, city, region, postal_code].compact.join(', ')
  end

  def distance
    # This will be populated by geocoder when using near scope
    try(:distance_from_sql_query)
  end

  private

  def should_geocode?
    (address_changed? || city_changed? || region_changed? || postal_code_changed?) &&
      address.present? &&
      city.present?
  end
end