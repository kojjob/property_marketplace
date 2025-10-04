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

ActiveRecord::Schema[8.0].define(version: 2025_10_03_222829) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_amenities_on_category"
    t.index ["name"], name: "index_amenities_on_name", unique: true
  end

  create_table "blog_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_blog_categories_on_slug", unique: true
  end

  create_table "blog_post_categories", force: :cascade do |t|
    t.bigint "blog_post_id", null: false
    t.bigint "blog_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_category_id"], name: "index_blog_post_categories_on_blog_category_id"
    t.index ["blog_post_id", "blog_category_id"], name: "idx_on_blog_post_id_blog_category_id_d507501be3", unique: true
    t.index ["blog_post_id"], name: "index_blog_post_categories_on_blog_post_id"
  end

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.text "excerpt"
    t.string "slug", null: false
    t.boolean "published", default: false
    t.datetime "published_at"
    t.bigint "user_id", null: false
    t.string "meta_title"
    t.text "meta_description"
    t.string "meta_keywords"
    t.string "featured_image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_blog_posts_on_published"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["user_id"], name: "index_blog_posts_on_user_id"
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
    t.integer "payment_status", default: 0, null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "landlord_id", null: false
    t.index ["landlord_id"], name: "index_bookings_on_landlord_id"
    t.index ["listing_id", "check_in_date", "check_out_date"], name: "index_bookings_on_listing_and_dates"
    t.index ["listing_id"], name: "index_bookings_on_listing_id"
    t.index ["payment_status"], name: "index_bookings_on_payment_status"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["tenant_id"], name: "index_bookings_on_tenant_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.string "author_name"
    t.string "author_email"
    t.bigint "blog_post_id", null: false
    t.bigint "parent_id"
    t.string "status", default: "pending"
    t.datetime "approved_at"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_at"], name: "index_comments_on_approved_at"
    t.index ["blog_post_id", "status"], name: "index_comments_on_blog_post_id_and_status"
    t.index ["blog_post_id"], name: "index_comments_on_blog_post_id"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["status"], name: "index_comments_on_status"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "subject"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "participant1_id", null: false
    t.bigint "participant2_id", null: false
    t.datetime "last_message_at"
    t.boolean "archived", default: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_conversations_on_archived"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["participant1_id", "participant2_id"], name: "index_conversations_on_participant1_id_and_participant2_id", unique: true
    t.index ["participant1_id"], name: "index_conversations_on_participant1_id"
    t.index ["participant2_id"], name: "index_conversations_on_participant2_id"
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
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "reviews_count", default: 0
    t.index ["average_rating"], name: "index_listings_on_average_rating"
    t.index ["listing_type"], name: "index_listings_on_listing_type"
    t.index ["price"], name: "index_listings_on_price"
    t.index ["property_id"], name: "index_listings_on_property_id"
    t.index ["status", "available_from"], name: "index_listings_on_status_and_available_from"
    t.index ["status"], name: "index_listings_on_status"
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.bigint "conversation_id", null: false
    t.string "regarding_type"
    t.bigint "regarding_id"
    t.text "content", null: false
    t.integer "status", default: 0, null: false
    t.integer "message_type", default: 0, null: false
    t.datetime "read_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["regarding_type", "regarding_id"], name: "index_messages_on_regarding"
    t.index ["sender_id", "recipient_id"], name: "index_messages_on_sender_id_and_recipient_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["status"], name: "index_messages_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "payer_id", null: false
    t.bigint "payee_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.decimal "service_fee", precision: 10, scale: 2
    t.integer "status", default: 0, null: false
    t.integer "payment_type", null: false
    t.integer "payment_method"
    t.string "transaction_id", null: false
    t.string "transaction_reference"
    t.datetime "processed_at"
    t.datetime "refunded_at"
    t.string "failure_reason"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "status"], name: "index_payments_on_booking_id_and_status"
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["payee_id", "created_at"], name: "index_payments_on_payee_id_and_created_at"
    t.index ["payee_id"], name: "index_payments_on_payee_id"
    t.index ["payer_id", "created_at"], name: "index_payments_on_payer_id_and_created_at"
    t.index ["payer_id"], name: "index_payments_on_payer_id"
    t.index ["payment_type"], name: "index_payments_on_payment_type"
    t.index ["processed_at"], name: "index_payments_on_processed_at"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id", unique: true
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
    t.string "company_name"
    t.string "position"
    t.integer "years_experience"
    t.string "languages"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "website"
    t.string "facebook_url"
    t.string "twitter_url"
    t.string "linkedin_url"
    t.string "instagram_url"
    t.boolean "allow_messages", default: true, null: false
    t.string "messaging_availability", default: "everyone"
    t.index ["allow_messages"], name: "index_profiles_on_allow_messages"
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
    t.string "region"
    t.string "postal_code"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "featured", default: false
    t.string "listing_type", default: "sale"
    t.string "country"
    t.text "formatted_address"
    t.index ["country"], name: "index_properties_on_country"
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

  create_table "reviews", force: :cascade do |t|
    t.string "reviewable_type", null: false
    t.bigint "reviewable_id", null: false
    t.bigint "reviewer_id", null: false
    t.bigint "booking_id"
    t.integer "rating", null: false
    t.string "title", limit: 100
    t.text "content"
    t.integer "review_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "helpful_count", default: 0
    t.text "response"
    t.bigint "response_by_id"
    t.datetime "response_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "review_type"], name: "index_reviews_on_booking_and_type", unique: true, where: "(booking_id IS NOT NULL)"
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["review_type"], name: "index_reviews_on_review_type"
    t.index ["reviewable_type", "reviewable_id", "status"], name: "index_reviews_on_reviewable_and_status"
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewable"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["status"], name: "index_reviews_on_status"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.json "criteria"
    t.integer "frequency"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_saved_searches_on_user_id"
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
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "verifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "verified_by_id"
    t.integer "verification_type", null: false
    t.integer "status", default: 0, null: false
    t.string "document_url"
    t.text "rejection_reason"
    t.datetime "verified_at"
    t.datetime "expires_at"
    t.datetime "expired_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_verifications_on_created_at"
    t.index ["expires_at"], name: "index_verifications_on_expires_at"
    t.index ["status"], name: "index_verifications_on_status"
    t.index ["user_id", "verification_type"], name: "index_verifications_on_user_id_and_verification_type"
    t.index ["user_id"], name: "index_verifications_on_user_id"
    t.index ["verification_type"], name: "index_verifications_on_verification_type"
    t.index ["verified_by_id"], name: "index_verifications_on_verified_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blog_post_categories", "blog_categories"
  add_foreign_key "blog_post_categories", "blog_posts"
  add_foreign_key "blog_posts", "users"
  add_foreign_key "bookings", "listings"
  add_foreign_key "bookings", "users", column: "landlord_id"
  add_foreign_key "bookings", "users", column: "tenant_id"
  add_foreign_key "comments", "blog_posts"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "users"
  add_foreign_key "conversations", "users", column: "participant1_id"
  add_foreign_key "conversations", "users", column: "participant2_id"
  add_foreign_key "favorites", "properties"
  add_foreign_key "favorites", "users"
  add_foreign_key "listing_amenities", "amenities"
  add_foreign_key "listing_amenities", "listings"
  add_foreign_key "listings", "properties"
  add_foreign_key "listings", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "users", column: "payee_id"
  add_foreign_key "payments", "users", column: "payer_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_images", "properties"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "users", column: "response_by_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "saved_searches", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "verifications", "users"
  add_foreign_key "verifications", "users", column: "verified_by_id"
end
