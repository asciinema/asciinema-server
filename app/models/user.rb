class User < ActiveRecord::Base

  validate :provider, :presence => true
  validate :uid, :presence => true

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid      = auth["uid"]
      user.name     = auth["user_info"]["name"]
      user.email    = auth["user_info"]["email"]
    end
  end

end
