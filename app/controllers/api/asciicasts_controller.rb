module Api
  class AsciicastsController < BaseController

    respond_to :html, only: [:show]

    attr_reader :asciicast

    def create
      asciicast = asciicast_creator.create(asciicast_attributes)
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

    def asciicast_attributes
      username, token = basic_auth_credentials
      AsciicastParams.build(params[:asciicast], username, token, request.user_agent)
    end

    def basic_auth_credentials
      authenticate_with_http_basic { |username, password| [username, password] }
    end

    def asciicast_creator
      AsciicastCreator.new
    end

    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
    end

  end
end
