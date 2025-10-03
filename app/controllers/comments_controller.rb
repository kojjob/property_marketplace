class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_comment, only: [ :update, :destroy, :approve, :reject ]
  before_action :set_blog_post, only: [ :create ]
  before_action :authorize_comment, only: [ :update, :destroy, :approve, :reject ]

  def create
    @comment = @blog_post.comments.build(comment_params)
    @comment.user = current_user if user_signed_in?

    if @comment.save
      # Auto-approve replies to approved comments
      @comment.approve! if @comment.parent&.approved?

      respond_to do |format|
        format.html { redirect_to @blog_post, notice: "Comment was successfully posted." }
        format.turbo_stream
        format.json { render json: @comment, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          @related_posts = @blog_post.categories.flat_map(&:blog_posts).uniq.select(&:published?).reject { |p| p.id == @blog_post.id }.first(3)
          render "blog_posts/show", status: :unprocessable_entity
        end
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form", locals: { comment: @comment, blog_post: @blog_post }) }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to @comment.blog_post, notice: "Comment was successfully updated." }
        format.turbo_stream
        format.json { render json: @comment, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render "blog_posts/show", status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, partial: "comments/comment", locals: { comment: @comment }) }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to @comment.blog_post, notice: "Comment was successfully deleted." }
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  def approve
    @comment.approve!

    respond_to do |format|
      format.html { redirect_to @comment.blog_post, notice: "Comment was approved." }
      format.turbo_stream
      format.json { render json: @comment, status: :ok }
    end
  end

  def reject
    @comment.reject!

    respond_to do |format|
      format.html { redirect_to @comment.blog_post, notice: "Comment was rejected." }
      format.turbo_stream
      format.json { render json: @comment, status: :ok }
    end
  end

  private

  def set_blog_post
    @blog_post = params[:blog_post_id] =~ /\A\d+\z/ ? BlogPost.find(params[:blog_post_id]) : BlogPost.find_by!(slug: params[:blog_post_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def authorize_comment
    case action_name
    when "update", "destroy"
      unless @comment.user == current_user || current_user.admin?
        redirect_to @comment.blog_post, alert: "You are not authorized to perform this action."
      end
    when "approve", "reject"
      unless current_user.admin?
        redirect_to @comment.blog_post, alert: "You are not authorized to moderate comments."
      end
    end
  end

  def comment_params
    params.require(:comment).permit(:content, :author_name, :author_email, :parent_id)
  end
end
