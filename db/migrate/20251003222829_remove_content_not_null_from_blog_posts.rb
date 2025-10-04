class RemoveContentNotNullFromBlogPosts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :blog_posts, :content, true
  end
end
