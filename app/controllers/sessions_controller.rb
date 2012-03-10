class SessionsController < ApplicationController
  before_filter :load_omniauth_auth, :only => :create

  def new; end

  def create
    @user =
      User.find_by_provider_and_uid(@auth["provider"], @auth["uid"]) ||
      User.create_with_omniauth(@auth)

    unless @user.persisted?
      store_sensitive_user_data_in_session
      render 'users/new', :status => 422
    else
      self.current_user = @user
      redirect_back_or_to root_url, :notice => "Signed in!"
    end
  end

  def destroy
    self.current_user = nil
    redirect_to root_url, :notice => "Signed out!"
  end

  def failure
    redirect_to root_url, :alert => params[:message]
  end

  private

  def load_omniauth_auth
    @auth = request.env["omniauth.auth"]
  end

  def store_sensitive_user_data_in_session
    session[:provider] = @user.provider
    session[:uid] = @user.uid
  end

end
