class AddPaymentFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :payment_status, :integer, default: 0, null: false
    add_column :bookings, :total_amount, :decimal, precision: 12, scale: 2, null: false, default: 0.0

    add_index :bookings, :payment_status
  end
end
