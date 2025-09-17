class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :check_owner, only: [:edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @properties = Property.active

    # Listing type filter (rent/sale)
    if params[:listing_type].present?
      @properties = @properties.where(listing_type: params[:listing_type])
    end

    # Property type filter (multi-select)
    if params[:property_types].present? && params[:property_types].is_a?(Array)
      @properties = @properties.where(property_type: params[:property_types])
    elsif params[:property_type].present?
      @properties = @properties.where(property_type: params[:property_type])
    end

    # Location filters
    @properties = @properties.where(city: params[:city]) if params[:city].present?
    @properties = @properties.where(region: params[:region]) if params[:region].present?
    @properties = @properties.where(country: params[:country]) if params[:country].present?

    # Bedroom and bathroom filters
    if params[:bedrooms].present? && params[:bedrooms] != ''
      @properties = @properties.where('bedrooms >= ?', params[:bedrooms])
    end
    if params[:bathrooms].present? && params[:bathrooms] != ''
      @properties = @properties.where('bathrooms >= ?', params[:bathrooms])
    end

    # Price range filter
    @properties = @properties.where('price >= ?', params[:min_price]) if params[:min_price].present?
    @properties = @properties.where('price <= ?', params[:max_price]) if params[:max_price].present?

    # Square feet filter
    @properties = @properties.where('square_feet >= ?', params[:min_sqft]) if params[:min_sqft].present?
    @properties = @properties.where('square_feet <= ?', params[:max_sqft]) if params[:max_sqft].present?

    # Features filter
    if params[:features].present? && params[:features].is_a?(Array)
      params[:features].each do |feature|
        case feature
        when 'featured'
          @properties = @properties.where(featured: true)
        when 'parking'
          # You'd need to add these columns to the properties table
          # For now, we'll skip these unless they exist
        end
      end
    end

    # Apply search if using pg_search
    @properties = @properties.search_full_text(params[:search]) if params[:search].present?

    # Sorting
    case params[:sort]
    when 'price_asc'
      @properties = @properties.order(price: :asc)
    when 'price_desc'
      @properties = @properties.order(price: :desc)
    when 'newest'
      @properties = @properties.order(created_at: :desc)
    when 'bedrooms'
      @properties = @properties.order(bedrooms: :desc)
    when 'sqft'
      @properties = @properties.order(square_feet: :desc)
    else
      @properties = @properties.order(created_at: :desc)
    end

    # Pagination (if needed)
    @properties = @properties.page(params[:page]) if defined?(Kaminari)

    # Respond to both HTML and Turbo Stream requests
    respond_to do |format|
      format.html
      format.turbo_stream
    end
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
    # Handle image attachments separately to prevent losing existing images
    update_params = property_params

    # If images array is empty or not present, don't update images
    if params[:property][:images].present? && params[:property][:images].reject(&:blank?).empty?
      update_params = update_params.except(:images)
    end

    # Same for videos and vr_content
    if params[:property][:videos].present? && params[:property][:videos].reject(&:blank?).empty?
      update_params = update_params.except(:videos)
    end

    if params[:property][:vr_content].present? && params[:property][:vr_content].reject(&:blank?).empty?
      update_params = update_params.except(:vr_content)
    end

    if @property.update(update_params)
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
    params.require(:property).permit(
      :title, :description, :price, :property_type, :listing_type,
      :bedrooms, :bathrooms, :square_feet,
      :address, :city, :region, :postal_code, :country, :status,
      # Also accept old field names for backward compatibility
      :state, :zip_code,
      images: [], videos: [], vr_content: []
    )
  end
end