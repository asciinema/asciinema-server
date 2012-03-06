class UserTokensController < ApplicationController
  before_filter :ensure_authenticated!

  def create
    ut = current_user.add_user_token(params[:user_token])

    if ut.valid?
      claimed_num = Asciicast.assign_user(ut.token, current_user)

      if claimed_num > 0
        notice = "Claimed #{claimed_num} asciicasts, yay!"
      else
        notice = "Authenticated successfully, yippie!"
      end

      redirect_to profile_path(current_user), :notice => notice
    else
      render :error
    end
  end
end
