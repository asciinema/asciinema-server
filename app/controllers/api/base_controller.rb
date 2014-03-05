module Api
  class BaseController < ApplicationController

    skip_before_filter :verify_authenticity_token

    private

    def authenticate
      warden.authenticate(:api_token)
    end

  end
end
