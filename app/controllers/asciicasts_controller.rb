class AsciicastsController < ApplicationController
  PER_PAGE = 15

  before_filter :load_resource, :only => [:show, :raw, :edit, :update, :destroy]
  before_filter :count_view, :only => [:show]
  before_filter :ensure_authenticated!, :only => [:edit, :update, :destroy]
  before_filter :ensure_owner!, :only => [:edit, :update, :destroy]

  respond_to :html, :json, :js

  def index
    @asciicasts = PaginatingDecorator.new(
      Asciicast.newest_paginated(params[:page], PER_PAGE)
    )

    @category_name = "All Asciicasts"
    @current_category = :all
  end

  def popular
    @asciicasts = PaginatingDecorator.new(
      Asciicast.popular_paginated(params[:page], PER_PAGE)
    )

    @category_name = "Popular Asciicasts"
    @current_category = :popular

    render :index
  end

  def show
    respond_to do |format|
      format.html do
        @asciicast = AsciicastDecorator.new(@asciicast)
        @title = @asciicast.title
        respond_with @asciicast
      end

      format.json do
        if stale? @asciicast
          respond_with AsciicastJSONDecorator.new(@asciicast)
        end
      end

      format.js do
        respond_with @asciicast
      end
    end
  end

  def raw
    @asciicast = AsciicastDecorator.new(@asciicast)
    render :layout => 'raw'
  end

  def edit
  end

  def update
    if @asciicast.update_attributes(params[:asciicast])
      redirect_to asciicast_path(@asciicast),
                  :notice => 'Asciicast was updated.'
    else
      render :edit
    end
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
    if current_user != @asciicast.user
      redirect_to asciicast_path(@asciicast), :alert => "You can't do that."
    end
  end
end
