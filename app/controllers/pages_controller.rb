class PagesController < ApplicationController
  before_action :authenticate_user!, except: [:home]

  def home
    @featured_properties = Property.includes(:property_images, :user)
                                  .where(featured: true)
                                  .limit(6)
    # Fallback to recent properties if no featured ones
    if @featured_properties.empty?
      @featured_properties = Property.includes(:property_images, :user)
                                    .order(created_at: :desc)
                                    .limit(6)
    end
  end
end