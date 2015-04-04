module Api
  class AsciicastsController < BaseController

    before_filter :ensure_authenticated!, only: :create

    respond_to :html, only: [:show]

    attr_reader :asciicast

    def create
      asciicast = asciicast_creator.create(asciicast_attributes)
      render text: asciicast_url(asciicast), status: :created,
        location: asciicast

    rescue ActiveRecord::RecordInvalid => e
      render text: e.record.errors.messages, status: 422
    rescue AsciicastParams::FormatError => e
      render text: e.message, status: 400
    end

    def show
      @asciicast = Asciicast.find(params[:id])

      respond_with(asciicast) do |format|
        format.html do
          allow_iframe_requests
          render locals: {
            page: BareAsciicastPagePresenter.build(asciicast, params)
          }, layout: 'bare'
        end
      end
    end

    private

    def asciicast_attributes
      AsciicastParams.build(params[:asciicast], current_user, request.user_agent)
    end

    def asciicast_creator
      AsciicastCreator.new
    end

    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
    end

  end
end
