class User < ActiveRecord::Base

  validate :provider, :presence => true
  validate :uid, :presence => true
  validate :nickname, :presence => true

  has_many :user_tokens

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider   = auth["provider"]
      user.uid        = auth["uid"]
      user.nickname   = auth["info"]["nickname"]
      user.name       = auth["info"]["name"]
      user.avatar_url = OauthHelper.get_avatar_url(auth)
    end
  end

  def add_user_token(token)
    user_tokens.find_or_create_by_token(token)
  end
end
