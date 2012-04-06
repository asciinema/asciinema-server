class AsciicastsController < ApplicationController
  PER_PAGE = 20

  before_filter :load_resource, :only => [:show, :edit, :update, :destroy]
  before_filter :ensure_authenticated!, :only => [:edit, :update, :destroy]
  before_filter :ensure_owner!, :only => [:edit, :update, :destroy]

  respond_to :html, :json

  def index
    collection = Asciicast.
                   order("created_at DESC").
                   page(params[:page]).
                   per(PER_PAGE)

    @asciicasts = AsciicastDecorator.decorate(collection)
  end

  def show
    respond_to do |format|
      format.html do
        @asciicast = AsciicastDecorator.new(@asciicast)
        @title = @asciicast.smart_title
      end

      format.json do
        respond_with @asciicast
      end
    end
  end

  def edit
  end

  def update
    @asciicast.update_attributes(params[:asciicast])
    redirect_to asciicast_path(@asciicast),
                :notice => 'Your asciicast was updated.'
  end

  def destroy
    if @asciicast.destroy
      redirect_to profile_path(current_user),
                  :notice => 'Your asciicast was deleted.'
    else
      redirect_to asciicast_path(@asciicast),
                  :alert => "Oops, we couldn't remove this asciicast. Sorry."
    end
  end

  private

  def load_resource
    @asciicast = Asciicast.find(params[:id])
  end

  def ensure_owner!
    if @asciicast.user != current_user
      redirect_to asciicast_path(@asciicast), :alert => "You can't do that."
    end
  end
end
