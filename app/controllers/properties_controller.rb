class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :check_owner, only: [:edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @properties = Property.active

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
      :title, :description, :price, :property_type,
      :bedrooms, :bathrooms, :square_feet,
      :address, :city, :state, :zip_code, :status
    )
  end
end