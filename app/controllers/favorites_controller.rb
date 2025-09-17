class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def index
    @favorite_properties = current_user.favorited_properties.includes(:property_images, :user)
    @favorites_count = @favorite_properties.count
  end
end
