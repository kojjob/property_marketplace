class AddAverageRatingToListings < ActiveRecord::Migration[8.0]
  def change
    add_column :listings, :average_rating, :decimal, precision: 3, scale: 2, default: 0.0
    add_column :listings, :reviews_count, :integer, default: 0

    add_index :listings, :average_rating
  end
end
