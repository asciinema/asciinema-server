class LoginsController < ApplicationController

  def new; end

  def create
    email = params[:email].strip

    if login_service.login(email)
      redirect_to sent_login_path, flash: { email_recipient: email }
    else
      @invalid_email = true
      render :new
    end
  end

  def sent
    @email_recipient = flash[:email_recipient]
    redirect_to new_login_path unless @email_recipient
  end

  private

  def login_service
    EmailLoginService.new
  end

end
