class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [ :show, :edit, :update ]
  before_action :ensure_profile_exists, only: [ :show, :edit, :update ]
  before_action :check_ownership, only: [ :edit, :update ]

  def show
    @user_properties = @profile.user.properties.includes(:property_images).limit(6)
    @reviews = @profile.user.received_reviews.includes(:reviewer).limit(10)
    @total_properties = @profile.user.properties.count
    @average_rating = @reviews.average(:rating)&.round(1) || 0
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Profile not found."
  end

  def ensure_profile_exists
    redirect_to root_path, alert: "Profile not found." unless @profile
  end

  def check_ownership
    unless @profile&.user == current_user
      redirect_to root_path, alert: "You can only edit your own profile."
    end
  end

  def profile_params
    params.require(:profile).permit(
      :first_name, :last_name, :phone_number, :bio, :company_name,
      :position, :years_experience, :languages, :address, :city,
      :state, :country, :website, :facebook_url, :twitter_url,
      :linkedin_url, :instagram_url, :avatar, :role
    )
  end
end
