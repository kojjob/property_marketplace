class AddListingTypeToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :listing_type, :string, default: 'sale'
  end
end
