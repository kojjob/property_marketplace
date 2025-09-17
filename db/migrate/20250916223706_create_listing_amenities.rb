class CreateListingAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :listing_amenities do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true
      t.timestamps
    end

    add_index :listing_amenities, [ :listing_id, :amenity_id ], unique: true
  end
end
