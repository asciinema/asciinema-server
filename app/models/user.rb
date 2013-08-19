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
    :message => "Sorry, but your nickname is already taken, " \
                "choose different one"

  has_many :user_tokens, :dependent => :destroy
  has_many :asciicasts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  attr_accessible :nickname, :email, :name

  def to_param
    nickname
  end

  def add_user_token(token)
    user_tokens.where(:token => token).first_or_create
  end

end
