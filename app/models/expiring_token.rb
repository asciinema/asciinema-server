class ExpiringToken < ActiveRecord::Base

  belongs_to :user

  validates :user, :token, :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where('expires_at > ?', Time.now) }

  def self.create_for_user(user)
    create!(
      user: user,
      token: SecureRandom.urlsafe_base64,
      expires_at: 15.minutes.from_now
    )
  end

  def self.active_for_token(token)
    active.where(token: token).first
  end

  def use!
    raise "token #{token} already used at #{used_at}" if used_at

    self.used_at = Time.now
    save!
  end

end
