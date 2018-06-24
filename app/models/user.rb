class User < ActiveRecord::Base

  USERNAME_FORMAT = /\A[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]\z/

  InvalidEmailError = Class.new(StandardError)

  has_many :api_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy

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

  def theme_name=(value)
    if value == ""
      value = nil
    end
    super(value)
  end

  def theme
    theme_name && Theme.for_name(theme_name)
  end

  def public_asciicast_count
    asciicasts.non_private.count
  end

  def asciicast_count
    asciicasts.count
  end

  def other_asciicasts(asciicast, limit)
    asciicasts.non_private.where('id <> ?', asciicast.id).order('RANDOM()').limit(limit)
  end

  def paged_asciicasts(page, per_page, include_private)
    asciicasts_scope(include_private).
      includes(:user).
      order("created_at DESC").
      paginate(page, per_page)
  end

  def new_asciicast_private?
    asciicasts_private_by_default?
  end

  private

  def generate_auth_token
    begin
      self[:auth_token] = self.class.generate_auth_token
    end while self.class.exists?(auth_token: self[:auth_token])
  end

  def asciicasts_scope(include_private)
    if include_private
      asciicasts
    else
      asciicasts.non_private
    end
  end

end
