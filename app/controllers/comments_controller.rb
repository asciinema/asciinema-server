class CommentsController < ApplicationController
  respond_to :json

  before_filter :ensure_authenticated!, :only => [:create, :update, :destroy]
  before_filter :load_asciicast, :only => [:index, :create]

  def index
    respond_with @asciicast.comments
  end

  def create
    @comment = Comment.new(params[:comment])
    @comment.asciicast = @asciicast
    @comment.user = current_user

    @comment.save

    respond_with @comment
  end

  #TODO Add Authorization
  def destroy
    comment = Comment.find(params[:id])
    if comment.user == current_user
      respond_with comment.delete
    else
      raise Forbiden
    end
  end

  private

  def load_asciicast
    @asciicast = Asciicast.find(params[:asciicast_id])
  end
end
