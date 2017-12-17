class UsersController < ApplicationController

  attr_reader :user

  def show
    if params[:username]
      user = User.for_username!(params[:username])
    else
      user = User.find(params[:id])
    end

    render locals: { page: UserPagePresenter.build(user, current_user, params[:page]) }
  end

end
