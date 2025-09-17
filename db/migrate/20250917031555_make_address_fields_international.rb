class MakeAddressFieldsInternational < ActiveRecord::Migration[8.0]
  def change
    # Rename US-specific 'state' to more international 'region'
    # region can be: state (US), province (Canada), county (UK), prefecture (Japan), canton (Switzerland), etc.
    rename_column :properties, :state, :region

    # Rename US-specific 'zip_code' to more international 'postal_code'
    # postal_code works for: ZIP codes (US), postcodes (UK), postal codes (Canada), etc.
    rename_column :properties, :zip_code, :postal_code

    # Add country field for international support
    add_column :properties, :country, :string, default: nil
    add_index :properties, :country

    # Add a formatted_address field for display purposes
    add_column :properties, :formatted_address, :text

    # Update existing records to have a default country if needed
    reversible do |direction|
      direction.up do
        # Only set USA as default for existing records that have a state value
        execute <<-SQL
          UPDATE properties
          SET country = 'United States'
          WHERE region IS NOT NULL
          AND country IS NULL
        SQL
      end
    end
  end
end
