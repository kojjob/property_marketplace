class CreateSavedSearches < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.json :criteria
      t.integer :frequency
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
