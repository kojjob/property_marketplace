class CreateListings < ActiveRecord::Migration[8.0]
  def change
    create_table :listings do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :listing_type, default: 0, null: false # 0: rent, 1: sale, 2: short_term, 3: subscription
      t.integer :status, default: 0, null: false # 0: draft, 1: active, 2: inactive, 3: archived
      t.date :available_from
      t.date :available_until
      t.integer :lease_duration
      t.integer :lease_duration_unit, default: 2 # 0: days, 1: weeks, 2: months, 3: years
      t.integer :minimum_stay
      t.integer :maximum_stay
      t.decimal :security_deposit, precision: 10, scale: 2
      t.boolean :utilities_included, default: false
      t.boolean :furnished, default: false
      t.boolean :pets_allowed, default: false
      t.integer :views_count, default: 0

      t.timestamps
    end

    add_index :listings, :listing_type
    add_index :listings, :status
    add_index :listings, [ :status, :available_from ]
    add_index :listings, :price
  end
end
