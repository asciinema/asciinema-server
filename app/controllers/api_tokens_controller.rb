class ApiTokensController < ApplicationController

  before_filter :ensure_authenticated!

  def create
    current_user.assign_api_token(params[:api_token])
    redirect_to profile_path(current_user),
      notice: "Successfully registered your API token. ^5"

  rescue ActiveRecord::RecordInvalid, ApiToken::ApiTokenTakenError
    render :error
  end

end
