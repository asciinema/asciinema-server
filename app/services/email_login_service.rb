class EmailLoginService

  def login(email)
    user = User.for_email!(email)
    expiring_token = ExpiringToken.create_for_user(user)
    Notifications.delay_login_request(expiring_token.user_id, expiring_token.token)
    true
  rescue User::InvalidEmailError
    false
  end

  def validate(token)
    expiring_token = ExpiringToken.active_for_token(token)

    if expiring_token
      expiring_token.use!
      expiring_token.user
    end
  end

end
