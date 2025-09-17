class Property::SearchService < ApplicationService
  def initialize(params = {})
    @params = params
  end

  def call
    properties = Property.active.includes(:user)
    properties = apply_filters(properties)
    properties = apply_search(properties)
    properties = apply_sorting(properties)

    paginated_properties, pagination_data = apply_pagination(properties)

    success(
      properties: paginated_properties,
      pagination: pagination_data
    )
  rescue => e
    failure(e.message)
  end

  private

  attr_reader :params

  def apply_filters(scope)
    scope = scope.where(city: params[:city]) if params[:city].present?
    scope = scope.where(property_type: params[:property_type]) if params[:property_type].present?
    scope = scope.where('price >= ?', params[:min_price]) if params[:min_price].present?
    scope = scope.where('price <= ?', params[:max_price]) if params[:max_price].present?
    scope = scope.where('bedrooms >= ?', params[:min_bedrooms]) if params[:min_bedrooms].present?
    scope = scope.where('bathrooms >= ?', params[:min_bathrooms]) if params[:min_bathrooms].present?
    scope = scope.where('square_feet >= ?', params[:min_square_feet]) if params[:min_square_feet].present?
    scope
  end

  def apply_search(scope)
    return scope unless params[:q].present?

    scope.search_full_text(params[:q])
  end

  def apply_sorting(scope)
    sort_column = params[:sort] || 'created_at'
    sort_order = params[:order] || 'desc'

    # Ensure valid sort columns to prevent SQL injection
    valid_columns = %w[price created_at bedrooms bathrooms square_feet]
    sort_column = 'created_at' unless valid_columns.include?(sort_column)
    sort_order = 'desc' unless %w[asc desc].include?(sort_order)

    scope.order("#{sort_column} #{sort_order}")
  end

  def apply_pagination(scope)
    page = [params[:page].to_i, 1].max
    per_page = [(params[:per_page] || 20).to_i, 50].min

    offset = (page - 1) * per_page
    total_count = scope.count

    properties = scope.offset(offset).limit(per_page)

    pagination_data = {
      current_page: page,
      per_page: per_page,
      total_pages: (total_count.to_f / per_page).ceil,
      total_count: total_count
    }

    [properties, pagination_data]
  end
end