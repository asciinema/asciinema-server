class SessionsController < ApplicationController

  def create
    user = login_service.validate(params[:token].to_s.strip)

    if user
      self.current_user = user
      redirect_back_or_to profile_path(user), notice: login_notice(user)
    else
      render :error
    end
  end

  def destroy
    self.current_user = nil
    redirect_to root_path, notice: "See you later!"
  end

  private

  def login_service
    EmailLoginService.new
  end

  def login_notice(user)
    if user.first_login?
      "Welcome to Asciinema!"
    else
      "Welcome back!"
    end
  end

end
