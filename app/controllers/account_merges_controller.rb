class AccountMergesController < ApplicationController

  def create
    user = find_user

    if user
      user.update_attribute(:email, store.delete(:new_user_email))
      self.current_user = user
      redirect_back_or_to root_url, notice: 'Welcome back!'
    else
      redirect_to new_user_path,
                  alert: 'Sorry, no account found. Try a different provider.'
    end
  end

  private

  def store
    session
  end

  def find_user
    User.for_credentials(omniauth_credentials)
  end

end
