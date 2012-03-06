class UsersController < ApplicationController
  PER_PAGE = 20

  def show
    @user = User.find_by_nickname(params[:nickname])
    @asciicasts =
      @user.asciicasts.order("created_at DESC").page(params[:page]).per(PER_PAGE)
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      self.current_user = @user
      redirect_back_or_to root_url, :notice => "Signed in!"
    else
      render 'users/new', :status => 422
    end
  end
end
