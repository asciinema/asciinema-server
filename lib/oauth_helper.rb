class OauthHelper

  def self.get_avatar_url(auth)
    if auth["provider"] == "twitter"
      auth["info"]["image"]
    elsif auth["provider"] == "github"
      auth["extra"]["raw_info"]["avatar_url"]
    end
  end

end
