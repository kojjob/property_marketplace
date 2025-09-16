class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.references :payee, null: false, foreign_key: { to_table: :users }

      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, limit: 3, null: false, default: 'USD'
      t.decimal :service_fee, precision: 10, scale: 2

      t.integer :status, null: false, default: 0
      t.integer :payment_type, null: false
      t.integer :payment_method

      t.string :transaction_id, null: false
      t.string :transaction_reference

      t.datetime :processed_at
      t.datetime :refunded_at
      t.string :failure_reason

      # For optimistic locking
      t.integer :lock_version, default: 0, null: false

      t.timestamps
    end

    add_index :payments, :transaction_id, unique: true
    add_index :payments, :status
    add_index :payments, :payment_type
    add_index :payments, [:booking_id, :status]
    add_index :payments, [:payer_id, :created_at]
    add_index :payments, [:payee_id, :created_at]
    add_index :payments, :processed_at
  end
end
