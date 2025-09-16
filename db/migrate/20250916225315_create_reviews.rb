class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :reviewable, polymorphic: true, null: false
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :booking, foreign_key: true, null: true
      t.integer :rating, null: false
      t.string :title, limit: 100
      t.text :content
      t.integer :review_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.integer :helpful_count, default: 0
      t.text :response
      t.bigint :response_by_id
      t.datetime :response_at

      t.timestamps
    end

    add_index :reviews, :rating
    add_index :reviews, :status
    add_index :reviews, :review_type
    add_index :reviews, [:reviewable_type, :reviewable_id, :status], name: 'index_reviews_on_reviewable_and_status'
    add_index :reviews, [:booking_id, :review_type], unique: true, where: "booking_id IS NOT NULL", name: 'index_reviews_on_booking_and_type'
    add_index :reviews, :created_at

    add_foreign_key :reviews, :users, column: :response_by_id
  end
end
