class AddLandlordIdToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings, :landlord, null: false, foreign_key: { to_table: :users }
  end
end
