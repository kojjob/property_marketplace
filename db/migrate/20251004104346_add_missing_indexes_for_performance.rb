class AddMissingIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    # Properties table indexes
    add_index :properties, :status
    add_index :properties, :property_type
    add_index :properties, :city
    add_index :properties, :price
    add_index :properties, :bedrooms
    add_index :properties, :bathrooms
    add_index :properties, :square_feet
    add_index :properties, :created_at
    add_index :properties, :featured
    add_index :properties, [ :latitude, :longitude ]
    add_index :properties, [ :status, :property_type ]
    add_index :properties, [ :status, :city ]
    add_index :properties, [ :status, :price ]
    add_index :properties, [ :status, :created_at ]

    # Listings table indexes
    add_index :listings, :available_from
    add_index :listings, :available_until
    add_index :listings, :created_at
    add_index :listings, [ :status, :available_from, :available_until ]
    add_index :listings, [ :status, :price ]
    add_index :listings, [ :status, :created_at ]

    # Messages table additional indexes
    add_index :messages, [ :sender_id, :created_at ]
    add_index :messages, [ :recipient_id, :created_at ]
    add_index :messages, [ :status, :created_at ]

    # Reviews table additional indexes
    add_index :reviews, [ :reviewable_type, :reviewable_id, :created_at ]
    add_index :reviews, [ :reviewer_id, :created_at ]
    add_index :reviews, [ :status, :created_at ]

    # Saved searches table indexes
    add_index :saved_searches, :frequency
    add_index :saved_searches, :last_run_at
    add_index :saved_searches, [ :user_id, :frequency ]
    add_index :saved_searches, [ :frequency, :last_run_at ]

    # Favorites table additional indexes
    add_index :favorites, [ :user_id, :property_id ], unique: true
    add_index :favorites, :created_at

    # Property images table indexes
    add_index :property_images, :position
    add_index :property_images, [ :property_id, :position ]

    # Verifications table additional indexes
    add_index :verifications, [ :status, :created_at ]
    add_index :verifications, [ :verification_type, :status ]
  end
end
