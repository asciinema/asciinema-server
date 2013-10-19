class OmniAuthHelper

  def self.get_avatar_url(auth)
    case auth["provider"]
    when "twitter"
      auth["info"]["image"]
    when "github"
      auth["extra"]["raw_info"]["avatar_url"]
    when "browser_id"
      email = auth["uid"]
      hash = Digest::MD5.hexdigest(email.to_s.downcase)
      "http://gravatar.com/avatar/#{hash}?s=64"
    end
  end

end
