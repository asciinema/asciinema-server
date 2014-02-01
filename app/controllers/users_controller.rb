class UsersController < ApplicationController

  before_filter :ensure_authenticated!, :only => [:edit, :update]

  attr_reader :user

  def new
    @user = build_user
  end

  def show
    user = User.find_by_nickname!(params[:nickname])
    render locals: { page: UserPagePresenter.build(user, current_user) }
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

    if @user.update_attributes(params[:user])
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
    user = User.new(params[:user])
    user.email = store[:new_user_email]

    user
  end

end
