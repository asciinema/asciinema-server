class UserTokenCreator

  def create(user, token)
    user_token = user.add_user_token(token)

    if user_token.persisted?
      assign_user_to_asciicasts(user_token.token, user)
    end
  end

  private

  def assign_user_to_asciicasts(token, user)
    Asciicast.where(:user_id => nil, :user_token => token).
    update_all(:user_id => user.id, :user_token => nil)
  end

end
