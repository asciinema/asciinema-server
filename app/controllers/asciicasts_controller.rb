class AsciicastsController < ApplicationController
  PER_PAGE = 20

  before_filter :load_resource, :only => [:show, :destroy]
  before_filter :ensure_authenticated!, :only => [:destroy]

  respond_to :html, :json

  def index
    @asciicasts = Asciicast.
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)
  end

  def show
    respond_with @asciicast
  end

  def destroy
    if @asciicast.user == current_user && @asciicast.destroy
      redirect_to profile_path(current_user),
                  :notice => 'Your asciicast was deleted.'
    else
      if current_user
        target = profile_path(current_user)
      else
        target = root_path
      end

      redirect_to target,
                  :alert => "Oops, we couldn't remove this asciicast. Sorry."
    end
  end

  private

  def load_resource
    @asciicast = Asciicast.find(params[:id])
  end
end
