class AsciicastsController < ApplicationController

  before_filter :load_resource, except: [:index]
  before_filter :ensure_authenticated!, only: [:edit, :update, :destroy]

  respond_to :html, :json

  attr_reader :asciicast

  def index
    render locals: {
      page: BrowsePagePresenter.build(
        policy_scope(Asciicast),
        params[:category],
        params[:order],
        params[:page]
      )
    }
  end

  def show
    respond_to do |format|
      format.html do
        view_counter.increment(asciicast, cookies)
        render locals: {
          page: AsciicastPagePresenter.build(self, asciicast, current_user, params)
        }
      end

      format.json do
        serve_file(asciicast.data, !!params[:dl])
      end

      format.png do
        asciicast_image_generator.generate(asciicast) if asciicast.image_stale?
        serve_file(asciicast.image)
      end
    end
  end

  def example
    render layout: 'example'
  end

  def edit
    authorize asciicast
  end

  def update
    authorize asciicast

    if asciicast_updater.update(asciicast, update_params)
      redirect_to asciicast_path(asciicast),
                  :notice => 'Asciicast was updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize asciicast

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
    @asciicast = Asciicast.find_by_id_or_secret_token!(params[:id])
  end

  def view_counter
    @view_counter ||= ViewCounter.new
  end

  def update_params
    params.require(:asciicast).permit(*policy(asciicast).permitted_attributes)
  end

  def asciicast_updater
    AsciicastUpdater.new
  end

  def asciicast_image_generator
    AsciicastImageGenerator.new(self)
  end

  def serve_file(uploader, as_attachment = false)
    opts = if as_attachment
             { query: { "response-content-disposition" => "attachment; filename=#{asciicast.download_filename}" } }
           else
             {}
           end

    url = uploader.url(opts)

    if url.starts_with?("/")
      send_file uploader.path, disposition: as_attachment ? 'attachment' : 'inline'
    else
      redirect_to url
    end
  end
end
