class Api::CommentsController < ApplicationController
  respond_to :json

  before_filter :ensure_authenticated!, :only => [:create, :destroy]
  before_filter :load_asciicast, :only => [:index, :create]

  def index
    respond_with CommentDecorator.decorate_collection(@asciicast.comments)
  end

  def create
    comment = Comment.new(params[:comment])
    comment.asciicast = @asciicast
    comment.user = current_user

    if comment.save
      notify_via_email(@asciicast.user, comment)
    end

    decorated_comment = CommentDecorator.new(comment)
    location = comment.persisted? ? api_comment_url(comment) : nil
    respond_with decorated_comment, :location => location
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

  def notify_via_email(user, comment)
    if user && user.email.present? && user != comment.user
      UserMailer.new_comment_email(user, comment).deliver
    end
  end
end
