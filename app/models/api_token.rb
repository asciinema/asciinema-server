class ApiToken < ActiveRecord::Base

  ApiTokenTakenError = Class.new(StandardError)

  belongs_to :user

  validates :user, :token, presence: true
  validates :token, uniqueness: true

  def self.for_token(token)
    where(token: token).first
  end

  def self.create_with_tmp_user!(token, username)
    transaction do
      ApiToken.create!(
        token: token,
        user: User.create!(temporary_username: username.presence),
      )
    end
  end

  def reassign_to(target_user)
    return if target_user == user
    raise ApiTokenTakenError if taken?

    user.merge_to(target_user)
  end

  private

  def taken?
    user.confirmed?
  end

end
