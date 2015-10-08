require 'authentication/warden_authentication'

module Api
  class BaseController < ActionController::Base

    include WardenAuthentication
    include RouteHelper

    private

    def warden_scope
      :api
    end

  end
end
