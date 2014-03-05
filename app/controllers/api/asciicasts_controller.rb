module Api
  class AsciicastsController < BaseController

    before_action :load_asciicast, only: [:show]

    respond_to :html, :js, only: [:show]

    attr_reader :asciicast

    def create
      asciicast = asciicast_creator.create(attributes)
      render text: asciicast_url(asciicast), status: :created,
        location: asciicast

    rescue ActiveRecord::RecordInvalid => e
      render nothing: true, status: 422
    end

    def show
      respond_with(asciicast) do |format|
        format.html do
          response.headers.delete('X-Frame-Options')
          render locals: {
            page: BareAsciicastPagePresenter.build(asciicast, params)
          }, layout: 'bare'
        end
      end
    end

    private

    def load_asciicast
      @asciicast = Asciicast.find(params[:id])
    end

    def attributes
      AsciicastParams.build(params[:asciicast], request.user_agent)
    end

    def asciicast_creator
      AsciicastCreator.new
    end

  end
end
