class ListingAmenity < ApplicationRecord
  belongs_to :listing
  belongs_to :amenity

  # Validations to prevent duplicate amenities for a listing
  validates :amenity_id, uniqueness: { scope: :listing_id }
end
