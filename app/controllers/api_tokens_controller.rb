class ApiTokensController < ApplicationController
  before_filter :ensure_authenticated!

  def create
    claimed_num = api_token_creator.create(current_user, params[:api_token])

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

  def api_token_creator
    @api_token_creator ||= ApiTokenCreator.new
  end

end
