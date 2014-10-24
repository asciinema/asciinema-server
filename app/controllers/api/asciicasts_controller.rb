module Api
  class AsciicastsController < BaseController

    respond_to :html, :js, only: [:show]

    attr_reader :asciicast

    def create
      asciicast = asciicast_creator.create(*parse_request)
      render text: asciicast_url(asciicast), status: :created,
        location: asciicast

    rescue ActiveRecord::RecordInvalid => e
      render nothing: true, status: 422
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

    def parse_request
      meta = JSON.parse(params[:asciicast][:meta].read)

      [
        AsciicastParams.build(params[:asciicast].merge(meta: meta), request.user_agent),
        authenticate_with_http_basic { |username, password| password } || meta.delete('user_token'),
        meta.delete('username'),
      ]
    end

    def asciicast_creator
      AsciicastCreator.new
    end

    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
    end

  end
end
