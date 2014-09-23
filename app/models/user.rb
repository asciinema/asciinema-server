class User < ActiveRecord::Base

  USERNAME_FORMAT = /\A[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]\z/

  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  validates :username, presence: true
  validates :username, uniqueness: { scope: :dummy, case_sensitive: false },
                       format: { with: USERNAME_FORMAT },
                       length: { minimum: 2, maximum: 16 },
                       unless: :dummy
  validates :email, presence: true, uniqueness: true, unless: :dummy

  scope :real, -> { where(dummy: false) }

  before_create :generate_auth_token

  def self.for_credentials(credentials)
    where(provider: credentials.provider, uid: credentials.uid).first
  end

  def self.for_email(email)
    if email
      where(email: email).first
    end
  end

  def self.real_for_username!(username)
    real.where(username: username).first!
  end

  def self.for_api_token(token)
    return nil if token.blank?

    joins(:api_tokens).where('api_tokens.token' => token).first
  end

  def self.for_auth_token(auth_token)
    where(auth_token: auth_token).first
  end

  def self.create_dummy(token, username)
    return nil if token.blank?
    username = 'anonymous' if username.blank?

    transaction do |tx|
      user = User.new
      user.dummy = true
      user.username = username
      user.save!
      user.api_tokens.create!(token: token)
      user
    end
  end

  def self.generate_auth_token
    SecureRandom.urlsafe_base64
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

  def to_param
    username
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

  private

  def generate_auth_token
    begin
      self[:auth_token] = self.class.generate_auth_token
    end while User.exists?(auth_token: self[:auth_token])
  end

end
