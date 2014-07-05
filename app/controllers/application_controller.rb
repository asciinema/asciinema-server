require 'authentication/warden_authentication'

class ApplicationController < ActionController::Base

  protect_from_forgery

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

  helper_method :decorated_current_user

  include WardenAuthentication
  include Pundit

  private

  def warden_strategies
    [:auth_cookie]
  end

  def decorated_current_user
    current_user && current_user.decorate
  end

  def ensure_authenticated!
    handle_unauthenticated unless current_user
  end

  def omniauth_credentials
    OmniAuthCredentials.new(request.env['omniauth.auth'])
  end

  def store_location
    session[:return_to] = request.path
  end

  def get_stored_location
    session.delete(:return_to)
  end

  def redirect_back_or_to(default, options = nil)
    path = get_stored_location || default

    if options
      redirect_to path, options
    else
      redirect_to path
    end
  end

  def handle_unauthorized
    if request.xhr?
      render json: "Unauthorized", status: 403
    else
      redirect_to(request.referrer || root_path, alert: "You can't do that.")
    end
  end

  def handle_unauthenticated
    if request.xhr?
      render json: "Unauthenticated", status: 401
    else
      store_location
      redirect_to login_path, notice: "Please sign in to proceed"
    end
  end

  def handle_not_found
    respond_to do |format|
      format.any do
        render text: 'Requested resource not found', status: 404
      end

      format.html do
        render 'application/not_found', status: 404, layout: 'application'
      end
    end
  end

end
