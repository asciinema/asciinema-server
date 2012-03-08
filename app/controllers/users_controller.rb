class UsersController < ApplicationController
  PER_PAGE = 20

  def show
    @user = User.find_by_nickname(params[:nickname])
    @asciicasts = @user.asciicasts.
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)
  end
end
