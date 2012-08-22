class Asciicast < ActiveRecord::Base
  mount_uploader :stdin, BasicUploader
  mount_uploader :stdin_timing, BasicUploader
  mount_uploader :stdout, BasicUploader
  mount_uploader :stdout_timing, BasicUploader

  validates :stdout, :stdout_timing, :presence => true
  validates :terminal_columns, :terminal_lines, :duration, :presence => true

  belongs_to :user
  has_many :comments, :order => :created_at, :dependent => :destroy
  has_many :likes, :dependent => :destroy

  scope :featured, where(:featured => true)

  before_create :assign_user, :unless => :user

  attr_accessible :meta, :stdout, :stdout_timing, :stdin, :stdin_timing,
                  :title, :description, :time_compression

  def self.assign_user(user_token, user)
    where(:user_id => nil, :user_token => user_token).
    update_all(:user_id => user.id, :user_token => nil)
  end

  def self.cache_key
    timestamps = scoped.select(:updated_at).map { |o| o.updated_at.to_i }
    Digest::MD5.hexdigest timestamps.join('/')
  end

  def meta=(file)
    data = JSON.parse(file.tempfile.read)

    self.username         = data['username']
    self.user_token       = data['user_token']
    self.duration         = data['duration']
    self.recorded_at      = data['recorded_at']
    self.title            = data['title']
    self.command          = data['command']
    self.shell            = data['shell']
    self.uname            = data['uname']
    self.terminal_lines   = data['term']['lines']
    self.terminal_columns = data['term']['columns']
    self.terminal_type    = data['term']['type']
  end

  def assign_user
    if user_token.present?
      if ut = UserToken.find_by_token(user_token)
        self.user = ut.user
        self.user_token = nil
      end
    end
  end
end
