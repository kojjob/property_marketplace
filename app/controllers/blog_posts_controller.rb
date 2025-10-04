class BlogPostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_blog_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_blog_post, only: [ :edit, :update, :destroy ]

  def index
    @blog_posts = BlogPost.published.includes(:user, :categories).recent
    @blog_posts = @blog_posts.by_category(params[:category]) if params[:category].present?
    @blog_posts = @blog_posts.search_full_text(params[:query]) if params[:query].present?

    @categories = BlogCategory.with_posts.alphabetical
  end

  def show
    @blog_post = BlogPost.includes(:user, :categories, comments: [ :user, :replies ]).find(params[:slug]) if params[:slug] =~ /\A\d+\z/
    @blog_post ||= BlogPost.includes(:user, :categories, comments: [ :user, :replies ]).find_by!(slug: params[:slug])
    @related_posts = @blog_post.categories.flat_map(&:blog_posts).uniq.select(&:published?).reject { |p| p.id == @blog_post.id }.first(3)
    @comment = Comment.new
  end

  def new
    @blog_post = current_user.blog_posts.build
    @categories = BlogCategory.alphabetical
  end

  def create
    @blog_post = current_user.blog_posts.build(blog_post_params)

    if @blog_post.save
      attach_featured_image if params[:blog_post][:featured_image].present?
      attach_media_files if params[:blog_post][:media_files].present?

      redirect_to @blog_post, notice: "Blog post was successfully created."
    else
      @categories = BlogCategory.alphabetical
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = BlogCategory.alphabetical
  end

  def update
    if @blog_post.update(blog_post_params)
      attach_featured_image if params[:blog_post][:featured_image].present?
      attach_media_files if params[:blog_post][:media_files].present?

      redirect_to @blog_post, notice: "Blog post was successfully updated."
    else
      @categories = BlogCategory.alphabetical
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog_post.destroy
    redirect_to blog_posts_url, notice: "Blog post was successfully destroyed."
  end

  private

  def set_blog_post
    @blog_post = params[:slug] =~ /\A\d+\z/ ? BlogPost.find(params[:slug]) : BlogPost.find_by!(slug: params[:slug])
  end

  def authorize_blog_post
    unless @blog_post.user == current_user || current_user.admin?
      redirect_to blog_posts_url, alert: "You are not authorized to perform this action."
    end
  end

  def blog_post_params
    params.require(:blog_post).permit(
      :title,
      :content,
      :excerpt,
      :published,
      :meta_title,
      :meta_description,
      :meta_keywords,
      category_ids: []
    )
  end

  def attach_featured_image
    @blog_post.featured_image.attach(params[:blog_post][:featured_image])
  end

  def attach_media_files
    Array(params[:blog_post][:media_files]).each do |file|
      @blog_post.media_files.attach(file)
    end
  end
end
