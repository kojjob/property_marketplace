class AddFieldsToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :company_name, :string
    add_column :profiles, :position, :string
    add_column :profiles, :years_experience, :integer
    add_column :profiles, :languages, :string
    add_column :profiles, :address, :string
    add_column :profiles, :city, :string
    add_column :profiles, :state, :string
    add_column :profiles, :country, :string
    add_column :profiles, :website, :string
    add_column :profiles, :facebook_url, :string
    add_column :profiles, :twitter_url, :string
    add_column :profiles, :linkedin_url, :string
    add_column :profiles, :instagram_url, :string
  end
end
