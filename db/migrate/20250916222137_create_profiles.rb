class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone_number
      t.date :date_of_birth
      t.text :bio
      t.integer :role, default: 0, null: false # 0: tenant, 1: landlord, 2: agent, 3: admin
      t.integer :verification_status, default: 0, null: false # 0: unverified, 1: pending, 2: verified

      t.timestamps
    end

    add_index :profiles, :role
    add_index :profiles, :verification_status
  end
end