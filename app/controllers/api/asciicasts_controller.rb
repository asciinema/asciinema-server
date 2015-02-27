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
      if legacy_format?
        attrs, username, token = parse_format_0_request
      else
        attrs, username, token = parse_format_1_request
      end

      user = User.for_api_token!(token, username)

      [attrs, user]
    end

    def legacy_format?
      !params[:asciicast].try(:respond_to?, :read)
    end

    def parse_format_0_request
      meta = JSON.parse(params[:asciicast][:meta].read)
      username, token = basic_auth_credentials
      token ||= meta.delete('user_token')
      username ||= meta.delete('username')
      attrs = AsciicastParams.from_format_0_request(params[:asciicast].merge(meta: meta), request.user_agent)

      [attrs, username, token]
    end

    def parse_format_1_request
      username, token = basic_auth_credentials
      attrs = AsciicastParams.from_format_1_request(params[:asciicast], request.user_agent)

      [attrs, username, token]
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
