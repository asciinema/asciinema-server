module Api
  class AsciicastsController < BaseController
    before_filter :ensure_authenticated!

    def create
      asciicast = asciicast_creator.create(asciicast_attributes)
      render text: asciicast_url(asciicast), status: :created,
        location: asciicast

    rescue ActiveRecord::RecordInvalid => e
      render text: e.record.errors.messages, status: 422
    rescue AsciicastParams::FormatError => e
      render text: e.message, status: 400
    end

    private

    def asciicast_attributes
      AsciicastParams.build(params[:asciicast], current_user, request.user_agent)
    end

    def asciicast_creator
      AsciicastCreator.new
    end
  end
end
