class CreateAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :amenities do |t|
      t.string :name, null: false
      t.string :icon
      t.string :category
      t.timestamps
    end

    add_index :amenities, :name, unique: true
    add_index :amenities, :category
  end
end
