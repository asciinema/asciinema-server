class NotFound < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(ActiveRecord::RecordNotFound) { render 'exceptions/not_found' }

  class Unauthorized < Exception; end
  class Forbidden < Exception; end

  rescue_from Unauthorized, :with => :unauthorized
  rescue_from Forbidden, :with => :forbidden

  helper_method :current_user

  def current_user
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
  end

  def current_user=(user)
    if user
      @current_user = user
      session[:user_id] = user.id
    else
      @current_user = nil
      session[:user_id] = nil
    end
  end

  private

  def ensure_authenticated!
    raise Unauthorized unless current_user
  end

  def store_location
    session[:return_to] = request.path
  end

  def get_stored_location
    session.delete(:return_to)
  end

  def forbidden
    if request.xhr?
      render :json => "Forbidden", :status => 403
    else
      redirect_to root_path, :alert => "This action is forbidden"
    end
  end

  def unauthorized
    if request.xhr?
      render :json => "Unauthorized", :status => 401
    else
      store_location
      redirect_to login_path, :notice => "Please login"
    end
  end
end
