# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_16_223730) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "amenities", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_amenities_on_category"
    t.index ["name"], name: "index_amenities_on_name", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "tenant_id", null: false
    t.date "check_in_date", null: false
    t.date "check_out_date", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_price", precision: 10, scale: 2
    t.integer "guests_count", default: 1
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "check_in_date", "check_out_date"], name: "index_bookings_on_listing_and_dates"
    t.index ["listing_id"], name: "index_bookings_on_listing_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["tenant_id"], name: "index_bookings_on_tenant_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_favorites_on_property_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "listing_amenities", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "amenity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_listing_amenities_on_amenity_id"
    t.index ["listing_id", "amenity_id"], name: "index_listing_amenities_on_listing_id_and_amenity_id", unique: true
    t.index ["listing_id"], name: "index_listing_amenities_on_listing_id"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "listing_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.date "available_from"
    t.date "available_until"
    t.integer "lease_duration"
    t.integer "lease_duration_unit", default: 2
    t.integer "minimum_stay"
    t.integer "maximum_stay"
    t.decimal "security_deposit", precision: 10, scale: 2
    t.boolean "utilities_included", default: false
    t.boolean "furnished", default: false
    t.boolean "pets_allowed", default: false
    t.integer "views_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_type"], name: "index_listings_on_listing_type"
    t.index ["price"], name: "index_listings_on_price"
    t.index ["property_id"], name: "index_listings_on_property_id"
    t.index ["status", "available_from"], name: "index_listings_on_status_and_available_from"
    t.index ["status"], name: "index_listings_on_status"
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number"
    t.date "date_of_birth"
    t.text "bio"
    t.integer "role", default: 0, null: false
    t.integer "verification_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_profiles_on_role"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
    t.index ["verification_status"], name: "index_profiles_on_verification_status"
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "description"
    t.decimal "price"
    t.string "property_type"
    t.integer "bedrooms"
    t.integer "bathrooms"
    t.integer "square_feet"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_images", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "image_url"
    t.string "caption"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_images_on_property_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "bookings", "listings"
  add_foreign_key "bookings", "users", column: "tenant_id"
  add_foreign_key "favorites", "properties"
  add_foreign_key "favorites", "users"
  add_foreign_key "listing_amenities", "amenities"
  add_foreign_key "listing_amenities", "listings"
  add_foreign_key "listings", "properties"
  add_foreign_key "listings", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_images", "properties"
  add_foreign_key "sessions", "users"
end
