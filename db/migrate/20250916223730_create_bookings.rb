class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.date :check_in_date, null: false
      t.date :check_out_date, null: false
      t.integer :status, default: 0, null: false # 0: pending, 1: confirmed, 2: cancelled, 3: completed
      t.decimal :total_price, precision: 10, scale: 2
      t.integer :guests_count, default: 1
      t.text :message
      t.timestamps
    end

    add_index :bookings, :status
    add_index :bookings, [ :listing_id, :check_in_date, :check_out_date ], name: 'index_bookings_on_listing_and_dates'
  end
end
