class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :property

  validates :user_id, uniqueness: { scope: :property_id, message: "has already favorited this property" }
end
