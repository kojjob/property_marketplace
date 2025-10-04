class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.text :excerpt
      t.string :slug, null: false
      t.boolean :published, default: false
      t.datetime :published_at
      t.references :user, null: false, foreign_key: true
      t.string :meta_title
      t.text :meta_description
      t.string :meta_keywords
      t.string :featured_image_url

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :published
    add_index :blog_posts, :published_at
  end
end
