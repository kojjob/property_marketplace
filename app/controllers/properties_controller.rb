class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :authenticate_user!, except: [:index, :show, :search, :autocomplete]
  before_action :check_owner, only: [:edit, :update, :destroy]

  def index
    @properties = Property.active.newest_first

    # Apply filters
    @properties = @properties.where(property_type: params[:property_type]) if params[:property_type].present?
    @properties = @properties.where(city: params[:city]) if params[:city].present?
    @properties = @properties.where(bedrooms: params[:bedrooms]) if params[:bedrooms].present?

    # Price range filter
    @properties = @properties.where('price >= ?', params[:min_price]) if params[:min_price].present?
    @properties = @properties.where('price <= ?', params[:max_price]) if params[:max_price].present?

    # Apply search if using pg_search
    @properties = @properties.search_full_text(params[:search]) if params[:search].present?

    # Pagination (if needed)
    @properties = @properties.page(params[:page]) if defined?(Kaminari)
  end

  def show
    @is_favorited = user_signed_in? && current_user.favorites.exists?(property: @property)
  end

  def new
    @property = current_user.properties.build
  end

  def create
    @property = current_user.properties.build(property_params)

    if @property.save
      redirect_to @property, notice: 'Property was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: 'Property was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_path, notice: 'Property was successfully deleted.'
  end

  def favorite
    @favorite = current_user.favorites.find_or_create_by(property: @property)
    redirect_back(fallback_location: @property, notice: 'Property added to favorites.')
  end

  def unfavorite
    @favorite = current_user.favorites.find_by(property: @property)
    @favorite&.destroy
    redirect_back(fallback_location: @property, notice: 'Property removed from favorites.')
  end

  def search
    @search_service = PropertySearchService.new(search_params, current_user)
    result = @search_service.call

    if result.success?
      @properties = result.data[:properties]
      @total_count = result.data[:total_count]
      @facets = result.data[:facets]
      @suggestions = result.data[:suggestions]

      respond_to do |format|
        format.html # search.html.erb
        format.json do
          render json: {
            properties: @properties.map { |p| property_json(p) },
            total_count: @total_count,
            page: result.data[:page],
            per_page: result.data[:per_page],
            total_pages: result.data[:total_pages],
            facets: @facets,
            suggestions: @suggestions,
            markers: params[:include_markers] ? properties_to_markers(@properties) : nil
          }
        end
      end
    else
      @properties = Property.none
      @error = result.error

      respond_to do |format|
        format.html { render :search }
        format.json { render json: { error: @error }, status: :unprocessable_entity }
      end
    end
  end

  def autocomplete
    service = PropertySearchService.new(params.permit(:q), current_user)
    suggestions = service.suggestions

    properties = Property.active
      .where('title ILIKE ?', "%#{params[:q]}%")
      .limit(5)
      .pluck(:id, :title, :city, :state, :price)
      .map do |id, title, city, state, price|
        {
          id: id,
          title: title,
          location: "#{city}, #{state}",
          price: price
        }
      end

    render json: {
      suggestions: suggestions,
      properties: properties.map { |p| p[:title] }
    }
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def check_owner
    unless @property.user == current_user
      redirect_to properties_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def property_params
    params.require(:property).permit(:title, :description, :price, :property_type,
                                      :bedrooms, :bathrooms, :square_feet,
                                      :address, :city, :state, :region, :zip_code, :postal_code, :status,
                                      property_images_attributes: [:id, :image, :caption, :position, :_destroy])
  end

  def search_params
    params.permit(:q, :query, :location, :address, :latitude, :longitude, :lat, :lng,
                  :radius, :min_price, :max_price, :bedrooms, :bathrooms,
                  :property_type, :min_sqft, :max_sqft, :sort, :sort_by,
                  :page, :per_page, :view, :save_search, :search_name,
                  :alert_frequency, :include_facets, :include_markers, :use_cache,
                  bounds: [:north, :south, :east, :west],
                  filters: {})
  end

  def property_json(property)
    {
      id: property.id,
      title: property.title,
      description: property.description.truncate(150),
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      square_feet: property.square_feet,
      property_type: property.property_type,
      address: property.address,
      city: property.city,
      state: property.state,
      latitude: property.latitude,
      longitude: property.longitude,
      image_url: property.primary_image&.image_url,
      url: property_path(property),
      distance: property.try(:distance)
    }
  end

  def properties_to_markers(properties)
    properties.map do |property|
      {
        lat: property.latitude,
        lng: property.longitude,
        title: property.title,
        price: property.price,
        id: property.id,
        info_window: render_to_string(
          partial: 'properties/map_info_window',
          locals: { property: property },
          formats: [:html]
        )
      }
    end
  rescue
    # If the partial doesn't exist yet, return simple markers
    properties.map do |property|
      {
        lat: property.latitude,
        lng: property.longitude,
        title: property.title,
        price: property.price,
        id: property.id
      }
    end
  end
end