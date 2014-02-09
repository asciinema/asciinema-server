class ApiTokenCreator

  def initialize(clock = DateTime)
    @clock = clock
  end

  def create(user, token)
    api_token = user.add_api_token(token)

    if api_token.persisted?
      update_asciicasts(api_token.token, user)
    end
  end

  private

  attr_reader :clock

  def update_asciicasts(token, user)
    Asciicast.where(:user_id => nil, :api_token => token).
    update_all(:user_id => user.id, :api_token => nil,
               :updated_at => clock.now)
  end

end
