class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :check_owner, only: [:edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # Use the Property::SearchService for all filtering, searching, and pagination
    search_params = normalize_search_params(params)
    result = Property::SearchService.new(search_params).call

    if result.success?
      @properties = result.data[:properties]
      @pagination = result.data[:pagination]
    else
      @properties = Property.none
      @pagination = {}
      flash.now[:alert] = "Search failed: #{result.error}"
    end

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

  def normalize_search_params(params)
    search_params = {}

    # Basic filters
    search_params[:city] = params[:city] if params[:city].present?
    search_params[:property_type] = params[:property_type] if params[:property_type].present?
    search_params[:min_price] = params[:min_price] if params[:min_price].present?
    search_params[:max_price] = params[:max_price] if params[:max_price].present?
    search_params[:min_bedrooms] = params[:bedrooms] if params[:bedrooms].present?
    search_params[:min_bathrooms] = params[:bathrooms] if params[:bathrooms].present?
    search_params[:min_square_feet] = params[:min_sqft] if params[:min_sqft].present?

    # Search query
    search_params[:q] = params[:search] if params[:search].present?

    # Sorting - convert controller sort params to service params
    case params[:sort]
    when 'price_asc'
      search_params[:sort] = 'price'
      search_params[:order] = 'asc'
    when 'price_desc'
      search_params[:sort] = 'price'
      search_params[:order] = 'desc'
    when 'newest'
      search_params[:sort] = 'created_at'
      search_params[:order] = 'desc'
    when 'bedrooms'
      search_params[:sort] = 'bedrooms'
      search_params[:order] = 'desc'
    when 'sqft'
      search_params[:sort] = 'square_feet'
      search_params[:order] = 'desc'
    end

    # Pagination
    search_params[:page] = params[:page] if params[:page].present?
    search_params[:per_page] = params[:per_page] if params[:per_page].present?

    search_params
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