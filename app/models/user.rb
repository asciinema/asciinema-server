class User < ActiveRecord::Base

  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  attr_accessible :nickname, :email, :name

  validates :nickname, presence: true
  validates :nickname, uniqueness: { scope: :dummy }, unless: :dummy
  validates :email, presence: true, uniqueness: true, unless: :dummy

  before_create :generate_auth_token

  def self.for_credentials(credentials)
    where(provider: credentials.provider, uid: credentials.uid).first
  end

  def self.for_email(email)
    where(email: email).first
  end

  def self.for_api_token(token, username)
    return nil if token.blank?

    user = User.joins(:api_tokens).where('api_tokens.token' => token).first
    user ? user : create_user_with_token(token, username)
  end

  def self.create_user_with_token(token, username)
    username = 'anonymous' if username.blank?

    transaction do |tx|
      user = User.new
      user.dummy = true
      user.nickname = username
      user.save!
      user.api_tokens.create!(token: token)
      user
    end
  end

  def self.generate_auth_token
    SecureRandom.urlsafe_base64
  end

  def nickname=(value)
    value ? super(value.strip) : super
  end

  def email=(value)
    value ? super(value.strip) : super
  end

  def to_param
    nickname
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

  def editable_by?(user)
    user && user.id == id
  end

  def paged_asciicasts(page, per_page)
    asciicasts.
      includes(:user).
      order("created_at DESC").
      paginate(page, per_page)
  end

  private

  def generate_auth_token
    begin
      self[:auth_token] = self.class.generate_auth_token
    end while User.exists?(auth_token: self[:auth_token])
  end

end
