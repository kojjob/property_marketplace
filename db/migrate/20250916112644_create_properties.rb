class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :price
      t.string :property_type
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :square_feet
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.decimal :latitude
      t.decimal :longitude
      t.string :status

      t.timestamps
    end
  end
end
