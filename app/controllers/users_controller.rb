class UsersController < ApplicationController

  before_filter :ensure_authenticated!, :only => [:edit, :update]

  attr_reader :user

  def show
    if params[:username]
      user = User.for_username!(params[:username])
    else
      user = User.find(params[:id])
    end

    render locals: { page: UserPagePresenter.build(user, current_user, params[:page]) }
  end

  def edit
    authorize current_user
    render locals: { page: UserEditPagePresenter.new(current_user) }
  end

  def update
    authorize current_user
    user = User.find(current_user.id)

    if user.update_attributes(update_params)
      redirect_to profile_path(user), notice: 'Account settings saved.'
    else
      render :edit, status: 422, locals: { page: UserEditPagePresenter.new(user) }
    end
  end

  private

  def update_params
    params.require(:user).permit(:username, :name, :email, :theme_name)
  end

end
