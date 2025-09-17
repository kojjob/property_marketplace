class PropertiesController < ApplicationController
  before_action :require_authentication, except: [:index, :show]
  before_action :set_property, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @properties = Property.active.recent

    # Apply filters if present
    @properties = @properties.where(property_type: params[:property_type]) if params[:property_type].present?
    @properties = @properties.where(city: params[:city]) if params[:city].present?
    @properties = @properties.where("price <= ?", params[:max_price]) if params[:max_price].present?
    @properties = @properties.where("price >= ?", params[:min_price]) if params[:min_price].present?
    @properties = @properties.where("bedrooms >= ?", params[:bedrooms]) if params[:bedrooms].present?
    @properties = @properties.where("bathrooms >= ?", params[:bathrooms]) if params[:bathrooms].present?
  end

  def show
    @is_favorited = current_user&.favorites&.exists?(property: @property)
  end

  def new
    @property = current_user.properties.build
  end

  def create
    @property = current_user.properties.build(property_params)

    if @property.save
      redirect_to @property, notice: 'Property was successfully listed.'
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
    redirect_to properties_path, notice: 'Property was successfully removed.'
  end

  def favorite
    current_user.favorites.create(property: @property)
    redirect_back(fallback_location: @property, notice: 'Property added to favorites.')
  end

  def unfavorite
    current_user.favorites.find_by(property: @property)&.destroy
    redirect_back(fallback_location: @property, notice: 'Property removed from favorites.')
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def authorize_owner!
    redirect_to properties_path, alert: 'Not authorized' unless @property.user == current_user
  end

  def property_params
    params.require(:property).permit(
      :title, :description, :price, :property_type,
      :bedrooms, :bathrooms, :square_feet,
      :address, :city, :state, :zip_code, :status,
      property_images_attributes: [:id, :image, :caption, :position, :_destroy]
    )
  end
end