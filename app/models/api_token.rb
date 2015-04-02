class ApiToken < ActiveRecord::Base

  ApiTokenTakenError = Class.new(StandardError)

  belongs_to :user

  validates :user, :token, presence: true
  validates :token, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where('revoked_at IS NOT NULL') }

  def self.for_token(token)
    ApiToken.where(token: token).first
  end

  def reassign_to(target_user)
    return if target_user == user
    raise ApiTokenTakenError if taken?

    user.merge_to(target_user)
  end

  def revoke!
    update!(revoked_at: Time.now)
  end

  private

  def taken?
    user.confirmed?
  end

end
