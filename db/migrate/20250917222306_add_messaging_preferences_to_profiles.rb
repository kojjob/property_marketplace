class AddMessagingPreferencesToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :allow_messages, :boolean, default: true, null: false
    add_column :profiles, :messaging_availability, :string, default: 'everyone'
    add_index :profiles, :allow_messages
  end
end
