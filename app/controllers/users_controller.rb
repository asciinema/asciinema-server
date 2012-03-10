class UsersController < ApplicationController
  PER_PAGE = 20

  def show
    @user = User.find_by_nickname(params[:nickname])
    @asciicasts = @user.asciicasts.
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)
  end

  def create
    @user = User.new(params[:user])
    load_sensitive_user_data_from_session
    if @user.save
      clear_sensitive_session_user_data
      self.current_user = @user
      redirect_back_or_to root_url, :notice => "Signed in!"
    else
      render 'users/new', :status => 422
    end
  end

  private

  def load_sensitive_user_data_from_session
    @user.provider = session[:provider]
    @user.uid = session[:uid]
  end

  def clear_sensitive_session_user_data
    session[:provider] = nil
    session[:uid] = nil
  end
end
