class BlogPostCategory < ApplicationRecord
  belongs_to :blog_post
  belongs_to :blog_category

  # Validations
  validates :blog_post_id, uniqueness: { scope: :blog_category_id }
end
