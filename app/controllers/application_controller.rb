class NotFound < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(ActiveRecord::RecordNotFound) { render 'exceptions/not_found' }

end
