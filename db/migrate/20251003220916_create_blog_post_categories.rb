class CreateBlogPostCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_post_categories do |t|
      t.references :blog_post, null: false, foreign_key: true
      t.references :blog_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :blog_post_categories, [ :blog_post_id, :blog_category_id ], unique: true
  end
end
