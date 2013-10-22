class UsersController < ApplicationController

  PER_PAGE = 15

  before_filter :ensure_authenticated!, :only => [:edit, :update]

  def new
    @user = build_user
  end

  def show
    @user = User.find_by_nickname!(params[:nickname]).decorate

    collection = @user.asciicasts.
      includes(:user).
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)

    @asciicasts = PaginatingDecorator.new(collection)
  end

  def create
    @user = build_user

    if @user.save
      store.delete(:new_user_email)
      self.current_user = @user
      redirect_back_or_to root_path, :notice => "Welcome to Asciinema!"
    else
      render :new, :status => 422
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

  def store
    session
  end

  def build_user
    user = User.new(params[:user])
    user.email = store[:new_user_email]

    user
  end

end
