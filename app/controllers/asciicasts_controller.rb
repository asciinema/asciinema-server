class AsciicastsController < ApplicationController
  PER_PAGE = 15

  before_filter :load_resource, :only => [:show, :raw, :edit, :update, :destroy]
  before_filter :count_view, :only => [:show]
  before_filter :ensure_authenticated!, :only => [:edit, :update, :destroy]
  before_filter :ensure_owner!, :only => [:edit, :update, :destroy]

  respond_to :html, :json

  def index
    collection = Asciicast.
      newest.
      includes(:user).
      page(params[:page]).
      per(PER_PAGE)

    @category_name = "All Asciicasts"
    @current_category = :all
    @asciicasts = AsciicastDecorator.decorate(collection)
  end

  def popular
    collection = Asciicast.
      popular.
      includes(:user).
      page(params[:page]).
      per(PER_PAGE)

    @category_name = "Popular Asciicasts"
    @current_category = :popular
    @asciicasts = AsciicastDecorator.decorate(collection)

    render :index
  end

  def show
    @asciicast = AsciicastDecorator.new(@asciicast)

    respond_to do |format|
      format.html do
        @asciicast_author = UserDecorator.new(@asciicast.user)
        @title = @asciicast.title
        respond_with @asciicast
      end

      format.json do
        if stale? @asciicast
          respond_with @asciicast
        end
      end
    end
  end

  def raw
    @asciicast = AsciicastDecorator.new(@asciicast)
    @asciicast_author = UserDecorator.new(@asciicast.user)
    render :layout => 'raw'
  end

  def edit
  end

  def update
    @asciicast.update_attributes(params[:asciicast])
    redirect_to asciicast_path(@asciicast),
                :notice => 'Asciicast was updated.'
  end

  def destroy
    if @asciicast.destroy
      redirect_to profile_path(current_user),
                  :notice => 'Asciicast was deleted.'
    else
      redirect_to asciicast_path(@asciicast),
                  :alert => "Oops, we couldn't remove this asciicast. " \
                            "Try again later."
    end
  end

  private

  def load_resource
    @asciicast = Asciicast.find(params[:id])
  end

  def count_view
    unless request.xhr?
      Asciicast.increment_counter :views_count, @asciicast.id
    end
  end

  def ensure_owner!
    if @asciicast.user != current_user
      redirect_to asciicast_path(@asciicast), :alert => "You can't do that."
    end
  end
end
