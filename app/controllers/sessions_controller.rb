class SessionsController < ApplicationController
  before_filter :load_omniauth_auth, :only => :create

  def new; end

  def create
    @user = request.env['asciiio.user']

    if @user.persisted? || @user.save
      self.current_user = @user
      redirect_back_or_to root_url, :notice => "Logged in!"
    else
      store_sensitive_user_data_in_session
      render 'users/new', :status => 422
    end
  end

  def destroy
    self.current_user = nil
    redirect_to root_url, :notice => "Logged out!"
  end

  def failure
    redirect_to root_url, :alert => "Authentication failed. Maybe try again?"
  end

  private

  def load_omniauth_auth
    @auth = request.env["omniauth.auth"]
  end

  def store_sensitive_user_data_in_session
    session[:new_user] = {
      :provider   => @user.provider,
      :uid        => @user.uid,
      :avatar_url => @user.avatar_url
    }
  end

end
