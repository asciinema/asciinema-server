class ApiToken < ActiveRecord::Base

  belongs_to :user

  validates :user, :token, presence: true
  validates :token, uniqueness: true, format: { with: /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/ }

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where('revoked_at IS NOT NULL') }
end
