class BlogPost < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :blog_post_categories, dependent: :destroy
  has_many :categories, through: :blog_post_categories, source: :blog_category

  # Active Storage attachments for rich media
  has_one_attached :featured_image do |attachable|
    attachable.variant :small, resize_to_limit: [ 300, 200 ]
    attachable.variant :thumb, resize_to_limit: [ 150, 150 ]
    attachable.variant :medium, resize_to_limit: [ 600, 400 ]
    attachable.variant :large, resize_to_limit: [ 1200, 800 ]
  end
  has_many_attached :media_files do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 150, 150 ]
    attachable.variant :medium, resize_to_limit: [ 600, 400 ]
  end
  has_rich_text :content

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :content, presence: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true
  validates :meta_title, length: { maximum: 60 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :meta_keywords, length: { maximum: 200 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { title.present? && slug.blank? }
  before_save :set_published_at, if: -> { published_changed? && published? }

  # Scopes
  scope :published, -> { where(published: true).where("published_at <= ?", Time.current) }
  scope :draft, -> { where(published: false) }
  scope :recent, -> { order("published_at DESC NULLS LAST") }
  scope :by_category, ->(category_slug) { joins(:categories).where(categories: { slug: category_slug }) }

  # PgSearch configuration for full-text search
  pg_search_scope :search_full_text,
                  against: {
                    title: "A",
                    content: "B",
                    excerpt: "C"
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

  def published?
    published
  end

  def draft?
    !published
  end

  def reading_time
    words_per_minute = 200
    word_count = content.to_plain_text.split.size
    (word_count / words_per_minute.to_f).ceil
  end

  def meta_title_or_title
    meta_title.presence || title
  end

  def meta_description_or_excerpt
    meta_description.presence || excerpt.presence || content.to_s.truncate(160)
  end

  private

  def generate_slug
    base_slug = title.parameterize
    slug_candidate = base_slug
    counter = 1

    while BlogPost.where(slug: slug_candidate).where.not(id: id).exists?
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def set_published_at
    self.published_at ||= Time.current
  end
end
