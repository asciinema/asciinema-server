class ApiToken < ActiveRecord::Base

  ApiTokenTakenError = Class.new(StandardError)

  belongs_to :user

  validates :user, :token, presence: true
  validates :token, uniqueness: true, format: { with: /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/ }

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where('revoked_at IS NOT NULL') }

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where('revoked_at IS NOT NULL') }

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

  def revoke!
    update!(revoked_at: Time.now)
  end

  private

  def taken?
    user.confirmed?
  end

end
