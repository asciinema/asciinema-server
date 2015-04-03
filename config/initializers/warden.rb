Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  User.find_by_id(id)
end

require 'auth_cookie_strategy'
require 'api_token_strategy'

Warden::Strategies.add(:auth_cookie, AuthCookieStrategy)
Warden::Strategies.add(:api_token, ApiTokenStrategy)
