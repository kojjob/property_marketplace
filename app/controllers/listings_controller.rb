class ListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_listing, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]
  before_action :set_user_properties, only: [:new, :edit]

  def index
    @listings = Listing.active.includes(:property, :user)

    # Apply search filters
    @listings = filter_by_location(@listings) if params[:location].present?
    @listings = filter_by_price_range(@listings) if price_params_present?
    @listings = filter_by_listing_type(@listings) if params[:listing_type].present?

  end

  def show
    @related_listings = Listing.active
                              .joins(:property)
                              .where(properties: { city: @listing.property.city })
                              .where.not(id: @listing.id)
                              .limit(3)
  end

  def new
    @listing = Listing.new
  end

  def create
    @listing = current_user.listings.build(listing_params)

    if @listing.save
      redirect_to @listing, notice: 'Listing was successfully created.'
    else
      set_user_properties
      render :new
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      redirect_to @listing, notice: 'Listing was successfully updated.'
    else
      set_user_properties
      render :edit
    end
  end

  def destroy
    @listing.destroy
    redirect_to listings_path, notice: 'Listing was successfully deleted.'
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def ensure_owner
    unless @listing.user == current_user
      redirect_to listings_path, alert: 'You are not authorized to edit this listing.'
    end
  end

  def set_user_properties
    @properties = current_user.properties if user_signed_in?
  end

  def listing_params
    params.require(:listing).permit(
      :property_id, :title, :description, :price, :security_deposit,
      :listing_type, :status, :available_from, :available_until, :minimum_stay,
      :maximum_stay, :lease_duration, :lease_duration_unit, :utilities_included,
      :furnished, :pets_allowed, amenity_ids: []
    )
  end

  def filter_by_location(scope)
    scope.joins(:property).where("properties.city ILIKE ? OR properties.country ILIKE ?",
                                 "%#{params[:location]}%", "%#{params[:location]}%")
  end

  def filter_by_price_range(scope)
    scope = scope.where("price >= ?", params[:min_price]) if params[:min_price].present?
    scope = scope.where("price <= ?", params[:max_price]) if params[:max_price].present?
    scope
  end

  def filter_by_listing_type(scope)
    scope.where(listing_type: params[:listing_type])
  end

  def price_params_present?
    params[:min_price].present? || params[:max_price].present?
  end
end