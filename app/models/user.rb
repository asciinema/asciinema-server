class User < ActiveRecord::Base

  USERNAME_FORMAT = /\A[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]\z/

  InvalidEmailError = Class.new(StandardError)

  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :expiring_tokens, dependent: :destroy

  validates :email, presence: true, on: :update
  validates :email, format: { with: /.+@.+\..+/i }, uniqueness: true, if: :email
  validates :username, uniqueness: { case_sensitive: false },
                       format: { with: USERNAME_FORMAT },
                       length: { minimum: 2, maximum: 16 },
                       if: :username

  scope :with_username, -> { where('username IS NOT NULL') }

  before_create :generate_auth_token

  def self.for_email!(email)
    raise InvalidEmailError if email.blank?

    self.where(email: email).first_or_create!

  rescue ActiveRecord::RecordInvalid => e
    if e.record.errors[:email].present?
      raise InvalidEmailError
    else
      raise e
    end
  end

  def self.for_username!(username)
    with_username.where(username: username).first!
  end

  def self.for_api_token(token)
    return nil if token.blank?

    joins(:api_tokens).where(
      'api_tokens.token' => token,
      'api_tokens.revoked_at' => nil,
    ).first
  end

  def self.for_auth_token(auth_token)
    where(auth_token: auth_token).first
  end

  def self.generate_auth_token
    SecureRandom.urlsafe_base64
  end

  def self.null
    new(temporary_username: 'anonymous')
  end

  def active_api_tokens
    api_tokens.active
  end

  def revoked_api_tokens
    api_tokens.revoked
  end

  def confirmed?
    email.present?
  end

  def username=(value)
    value ? super(value.strip) : super
  end

  def email=(value)
    value ? super(value.strip) : super
  end

  def theme
    theme_name.presence && Theme.for_name(theme_name)
  end

  def assign_api_token(token)
    api_token = ApiToken.for_token(token)

    if api_token
      api_token.reassign_to(self)
    else
      api_token = api_tokens.create!(token: token)
    end

    api_token
  end

  def merge_to(target_user)
    self.class.transaction do |tx|
      asciicasts.update_all(user_id: target_user.id, updated_at: DateTime.now)
      api_tokens.update_all(user_id: target_user.id, updated_at: DateTime.now)
      destroy
    end
  end

  def asciicast_count
    asciicasts.count
  end

  def asciicasts_excluding(asciicast, limit)
    asciicasts.where('id <> ?', asciicast.id).order('RANDOM()').limit(limit)
  end

  def paged_asciicasts(page, per_page)
    asciicasts.
      includes(:user).
      order("created_at DESC").
      paginate(page, per_page)
  end

  def admin?
    CFG.admin_ids.include?(id)
  end

  def first_login?
    expiring_tokens.count == 1
  end

  private

  def generate_auth_token
    begin
      self[:auth_token] = self.class.generate_auth_token
    end while self.class.exists?(auth_token: self[:auth_token])
  end

end
