class User < ActiveRecord::Base

  has_many :user_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :user_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  attr_accessible :nickname, :email, :name

  validates :nickname, :email, presence: true, uniqueness: true

  before_create :generate_auth_token

  def self.for_credentials(credentials)
    where(provider: credentials.provider, uid: credentials.uid).first
  end

  def self.for_email(email)
    where(email: email).first
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

  def add_user_token(token)
    user_tokens.where(:token => token).first_or_create
  end

  def asciicast_count
    asciicasts.count
  end

  private

  def generate_auth_token
    begin
      self[:auth_token] = self.class.generate_auth_token
    end while User.exists?(auth_token: self[:auth_token])
  end

end
