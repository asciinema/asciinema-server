class AsciicastsController < ApplicationController
  PER_PAGE = 15

  before_filter :load_resource, :only => [:show, :raw, :edit, :update, :destroy]
  before_filter :ensure_authenticated!, :only => [:edit, :update, :destroy]
  before_filter :ensure_owner!, :only => [:edit, :update, :destroy]

  respond_to :html, :json, :js

  def index
    @asciicasts = PaginatingDecorator.new(
      Asciicast.newest_paginated(params[:page], PER_PAGE)
    )

    @category_name = "All asciicasts"
    @current_category = :all
  end

  def popular
    @asciicasts = PaginatingDecorator.new(
      Asciicast.popular_paginated(params[:page], PER_PAGE)
    )

    @category_name = "Popular asciicasts"
    @current_category = :popular

    render :index
  end

  def show
    respond_to do |format|
      format.html do
        ViewCounter.new(@asciicast, cookies).increment
        @asciicast = AsciicastDecorator.new(@asciicast)
        @title = @asciicast.title
        respond_with @asciicast
      end

      format.json do
        response.headers['Cache-Control'] = 'no-cache' # prevent Rack from buffering
        self.response_body = AsciicastStreamer.new(@asciicast)
      end

      format.js do
        respond_with @asciicast
      end
    end
  end

  def raw
    response.headers.delete('X-Frame-Options')
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

  def ensure_owner!
    if current_user != @asciicast.user
      redirect_to asciicast_path(@asciicast), :alert => "You can't do that."
    end
  end
end
