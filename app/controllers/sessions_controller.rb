class SessionsController < ApplicationController

  def new; end

  def create
    user = find_user

    if user
      self.current_user = user
      redirect_back_or_to root_url, :notice => "Welcome back!"
    else
      store[:new_user_email] = omniauth_credentials.email
      redirect_to new_user_path
    end
  end

  def destroy
    self.current_user = nil
    redirect_to root_path, :notice => "See you later!"
  end

  def failure
    redirect_to root_path, :alert => "Authentication failed. Maybe try again?"
  end

  private

  def store
    session
  end

  def find_user
    User.for_email(omniauth_credentials.email)
  end

end
