class CreateVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :verified_by, foreign_key: { to_table: :users }

      t.integer :verification_type, null: false
      t.integer :status, default: 0, null: false
      t.string :document_url
      t.text :rejection_reason
      t.datetime :verified_at
      t.datetime :expires_at
      t.datetime :expired_at
      t.json :metadata

      t.timestamps
    end

    add_index :verifications, :verification_type
    add_index :verifications, :status
    add_index :verifications, [:user_id, :verification_type]
    add_index :verifications, :expires_at
    add_index :verifications, :created_at
  end
end
