module Api
  class AsciicastsController < BaseController

    respond_to :html, only: [:show]

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
      attrs, username, token = parse_format_0_request
      user = User.for_api_token!(token, username)

      [attrs, user]
    end

    def parse_format_0_request
      meta = JSON.parse(params[:asciicast][:meta].read)
      username, token = authenticate_with_http_basic { |username, password| [username, password] }
      token ||= meta.delete('user_token')
      username ||= meta.delete('username')
      attrs = AsciicastParams.build(params[:asciicast].merge(meta: meta), request.user_agent)

      [attrs, username, token]
    end

    def asciicast_creator
      AsciicastCreator.new
    end

    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
    end

  end
end
