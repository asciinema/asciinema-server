class Api::CommentsController < ApplicationController
  respond_to :json

  before_filter :ensure_authenticated!, :only => [:create, :destroy]
  before_filter :load_asciicast, :only => [:index, :create]

  def index
    respond_with CommentDecorator.decorate(@asciicast.comments)
  end

  def create
    @comment = Comment.new(params[:comment])
    @comment.asciicast = @asciicast
    @comment.user = current_user

    @comment.save

    comment = CommentDecorator.new(@comment)
    respond_with comment, :location => api_comment_url(@comment)
  end

  def destroy
    comment = Comment.find(params[:id])

    if comment.user == current_user
      respond_with comment.destroy
    else
      raise Forbidden
    end
  end

  private

  def load_asciicast
    @asciicast = Asciicast.find(params[:asciicast_id])
  end
end
