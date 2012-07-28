class User < ActiveRecord::Base

  has_many :user_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :likes, :dependent => :destroy

  validates :provider, :presence => true
  validates :uid, :presence => true
  validates :nickname, :presence => true

  validates_uniqueness_of \
    :nickname,
    :message => "Sorry, but your nickname is already taken, choose different one"

  has_many :user_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  attr_accessible :nickname, :email, :name

  def self.create_with_omniauth(auth)
    user = new
    user.provider   = auth["provider"]
    user.uid        = auth["uid"]
    user.nickname   = auth["info"]["nickname"]
    user.name       = auth["info"]["name"]
    user.avatar_url = OauthHelper.get_avatar_url(auth)
    user.save
    user
  end

  def to_param
    nickname
  end

  def add_user_token(token)
    user_tokens.find_or_create_by_token(token)
  end
end
