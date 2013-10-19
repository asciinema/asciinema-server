class OmniAuthCredentials

  attr_reader :omniauth_hash

  def initialize(omniauth_hash)
    @omniauth_hash = omniauth_hash
  end

  def provider
    omniauth_hash['provider']
  end

  def uid
    omniauth_hash['uid']
  end

  def email
    omniauth_hash['info'] && omniauth_hash['info']['email']
  end

end
