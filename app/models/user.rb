class User < ActiveRecord::Base

  validate :provider, :presence => true
  validate :uid, :presence => true

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider   = auth["provider"]
      user.uid        = auth["uid"]
      user.name       = auth["info"]["name"]
      user.avatar_url = OauthHelper.get_avatar_url(auth)
    end
  end

end
