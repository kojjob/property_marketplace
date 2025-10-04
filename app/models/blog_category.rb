class BlogCategory < ApplicationRecord
  include PgSearch::Model

  has_many :blog_post_categories, dependent: :destroy
  has_many :blog_posts, through: :blog_post_categories, source: :blog_post

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(name: :asc) }
  scope :with_posts, -> { joins(:blog_posts).distinct }

  # PgSearch configuration for full-text search
  pg_search_scope :search_full_text,
                  against: {
                    name: "A",
                    description: "B"
                  },
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english"
                    }
                  }

  # Methods
  def to_param
    slug
  end

  def post_count
    blog_posts.published.count
  end

  private

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1

    while BlogCategory.where(slug: slug_candidate).where.not(id: id).exists?
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end
end
