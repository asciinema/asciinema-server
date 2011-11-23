class NotFound < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(NotFound) { render 'exceptions/not_found' }

end
