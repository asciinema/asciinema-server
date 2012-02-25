class NotFound < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(ActiveRecord::RecordNotFound) { render 'exceptions/not_found' }

  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def current_user=(user)
    if user
      session[:user_id] = user.id
    else
      session[:user_id] = nil
    end
  end

end
