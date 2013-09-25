class UserTokenCreator

  def initialize(clock = DateTime)
    @clock = clock
  end

  def create(user, token)
    user_token = user.add_user_token(token)

    if user_token.persisted?
      update_asciicasts(user_token.token, user)
    end
  end

  private

  attr_reader :clock

  def update_asciicasts(token, user)
    Asciicast.where(:user_id => nil, :user_token => token).
    update_all(:user_id => user.id, :user_token => nil,
               :updated_at => clock.now)
  end

end
