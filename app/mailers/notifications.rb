class Notifications < ActionMailer::Base
  default from: CFG.smtp_from_address

  def self.delay_login_request(user_id, token)
    delay.login_request(user_id, token)
  end

  def login_request(user_id, token)
    user = User.find(user_id)
    @login_url = login_token_url(token)

    mail to: user.email
  end
end
