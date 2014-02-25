module Api
  module V0
    class AsciicastsController < ApplicationController

      skip_before_filter :verify_authenticity_token

      def create
        asciicast = asciicast_creator.create(attributes)
        render text: asciicast_url(asciicast), status: :created,
          location: asciicast

      rescue ActiveRecord::RecordInvalid => e
        render nothing: true, status: 422
      end

      private

      def attributes
        AsciicastParams.build(params[:asciicast], request.user_agent)
      end

      def asciicast_creator
        AsciicastCreator.new
      end

    end
  end
end
