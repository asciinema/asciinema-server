class SessionsController < ApplicationController

  def new; end

  def create
    @user = user_from_omniauth

    if @user.persisted?
      self.current_user = @user
      redirect_back_or_to root_url, :notice => "Logged in!"
    else
      store_sensitive_user_data_in_session
      redirect_to new_user_path
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

  def store_sensitive_user_data_in_session
    session[:new_user] = {
      :provider   => @user.provider,
      :uid        => @user.uid,
      :avatar_url => @user.avatar_url
    }
  end

  def user_from_omniauth
    omniauth = request.env['omniauth.auth']
    find_user(omniauth) || build_user(omniauth)
  end

  def find_user(omniauth)
    query = { :provider => omniauth['provider'], :uid => omniauth['uid'].to_s }

    User.where(query).first
  end

  def build_user(omniauth)
    user = User.new
    user.provider   = omniauth['provider']
    user.uid        = omniauth['uid']
    user.nickname   = omniauth['info']['nickname']
    user.name       = omniauth['info']['name'] unless user.provider == 'browser_id'
    user.email      = omniauth["info"]["email"]
    user.avatar_url = OmniAuthHelper.get_avatar_url(omniauth)

    user
  end

end
