class NotFound < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from(ActiveRecord::RecordNotFound) { render 'exceptions/not_found' }

  class Unauthorized < Exception; end
  class Forbiden < Exception; end

  rescue_from Unauthorized, :with => :unauthorized
  rescue_from Forbiden, :with => :forbiden

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

  def forbiden
    if request.xhr?
      render :json => "Forbiden", :status => 403
    else
      redirect_to root_path, :alert => "This action is forbiden"
    end
  end

  def unauthorized
    if request.xhr?
      render :json => "Unauthorized", :status => 401
    else
      redirect_to login_path, :notice => "Please login"
    end
  end
end
