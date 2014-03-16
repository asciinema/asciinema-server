module Api
  class BaseController < ApplicationController

    skip_before_filter :verify_authenticity_token

    private

    def warden_strategies
      [:api_token]
    end

  end
end
