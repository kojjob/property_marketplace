class CreatePropertyImages < ActiveRecord::Migration[8.0]
  def change
    create_table :property_images do |t|
      t.references :property, null: false, foreign_key: true
      t.string :image_url
      t.string :caption
      t.integer :position

      t.timestamps
    end
  end
end
