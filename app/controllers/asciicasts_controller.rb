class AsciicastsController < ApplicationController

  before_filter :load_resource, except: [:index, :oembed]
  before_filter :ensure_authenticated!, only: [:edit, :update, :destroy]
  before_filter :ensure_owner!, only: [:edit, :update, :destroy]

  respond_to :html

  attr_reader :asciicast

  def index
    render locals: {
      page: BrowsePagePresenter.build(params[:category], params[:order],
                                      params[:page])
    }
  end

  def show
    respond_to do |format|
      format.html do
        view_counter.increment(asciicast, cookies)
        render locals: {
          page: AsciicastPagePresenter.build(asciicast, current_user, params)
        }
      end
    end
  end

  def oembed
    if params[:format] != 'json'
      return head :not_implemented
    end
    url = params[:url]
    id = URI(url).path.split('/').last
    ascii = Asciicast.find(id)
    src = asciicast_url(ascii, format: :js)
    ascii_oembed = {
      "type" => "rich",
      "version" => "1.0",
      "html" => "<script type='text/javascript' src='#{src}' id='#{id}' async></script>",
      "width" => 599,
      "height" => 487,
      "title" => ascii.decorate.title,
      "description" => ascii.decorate.description,
    }
    render json: ascii_oembed, content_type: "application/json"
  end

  def example
    render layout: 'example'
  end

  def edit
  end

  def update
    if asciicast.update_attributes(update_params)
      redirect_to asciicast_path(asciicast),
                  :notice => 'Asciicast was updated.'
    else
      render :edit
    end
  end

  def destroy
    if asciicast.destroy
      redirect_to profile_path(current_user),
                  :notice => 'Asciicast was deleted.'
    else
      redirect_to asciicast_path(asciicast),
                  :alert => "Oops, we couldn't remove this asciicast. " \
                            "Try again later."
    end
  end

  private

  def load_resource
    @asciicast = Asciicast.find(params[:id])
  end

  def ensure_owner!
    if current_user != asciicast.user
      redirect_to asciicast_path(asciicast), :alert => "You can't do that."
    end
  end

  def view_counter
    @view_counter ||= ViewCounter.new
  end

  def update_params
    params.require(:asciicast).permit(:title, :description)
  end

end
