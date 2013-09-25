class UserTokensController < ApplicationController
  before_filter :ensure_authenticated!

  def create
    claimed_num = user_token_creator.create(current_user, params[:user_token])

    if claimed_num
      redirect_to_profile(claimed_num)
    else
      render :error
    end
  end

  private

  def redirect_to_profile(claimed_num)
    if claimed_num > 0
      notice = "Claimed #{claimed_num} asciicasts, yay!"
    else
      notice = "Authenticated successfully, yippie!"
    end

    redirect_to profile_path(current_user), :notice => notice
  end

  def user_token_creator
    @user_token_creator ||= UserTokenCreator.new
  end

end
