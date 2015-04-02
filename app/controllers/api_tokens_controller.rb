class ApiTokensController < ApplicationController

  before_filter :ensure_authenticated!

  def create
    current_user.assign_api_token(params[:api_token])
    redirect_to profile_path(current_user),
      notice: "Successfully registered your recorder token."

  rescue ActiveRecord::RecordInvalid, ApiToken::ApiTokenTakenError
    render :error
  end

  def destroy
    api_token = ApiToken.find(params[:id])
    authorize api_token
    api_token.revoke!
    redirect_to edit_user_path, notice: "Token revoked."
  end

end
