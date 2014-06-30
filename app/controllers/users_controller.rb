class UsersController < ApplicationController

  before_filter :ensure_authenticated!, :only => [:edit, :update]

  attr_reader :user

  def new
    @user = build_user
  end

  def show
    user = User.real_for_username!(params[:username])
    render locals: { page: UserPagePresenter.build(user, current_user, params[:page]) }
  end

  def create
    @user = build_user

    if @user.save
      store.delete(:new_user_email)
      self.current_user = @user
      redirect_to docs_path('getting-started'), notice: "Welcome to Asciinema!"
    else
      render :new, :status => 422
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)

    if @user.update_attributes(update_params)
      redirect_to profile_path(@user), notice: 'Account settings saved.'
    else
      render :edit, status: 422
    end
  end

  private

  def store
    session
  end

  def build_user
    user = User.new(create_params)
    user.email = store[:new_user_email]

    user
  end

  def create_params
    params.fetch(:user, {}).permit(:username, :name)
  end

  def update_params
    params.require(:user).permit(:username, :name, :email, :theme_name)
  end

end
