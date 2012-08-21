class UsersController < ApplicationController
  PER_PAGE = 15

  before_filter :ensure_authenticated!, :only => [:edit, :update]

  def show
    @user = UserDecorator.find_by_nickname!(params[:nickname])

    collection = @user.asciicasts.
      includes(:user).
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)

    @asciicasts = AsciicastDecorator.decorate(collection)
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

  def edit
    @user = current_user
  end

  def update
    current_user.update_attributes(params[:user])
    redirect_to profile_path(current_user),
                :notice => 'Account settings saved.'
  end

  private

  def load_sensitive_user_data_from_session
    if session[:new_user]
      @user.provider   = session[:new_user][:provider]
      @user.uid        = session[:new_user][:uid]
      @user.avatar_url = session[:new_user][:avatar_url]
    end
  end

  def clear_sensitive_session_user_data
    session.delete(:new_user)
  end
end
