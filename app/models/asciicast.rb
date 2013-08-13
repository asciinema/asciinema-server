class Asciicast < ActiveRecord::Base
  MAX_DELAY = 5.0

  mount_uploader :stdin_data,    StdinDataUploader
  mount_uploader :stdin_timing,  StdinTimingUploader
  mount_uploader :stdout_data,   StdoutDataUploader
  mount_uploader :stdout_timing, StdoutTimingUploader

  serialize :snapshot, JSON

  validates :stdout_data, :stdout_timing, :presence => true
  validates :terminal_columns, :terminal_lines, :duration, :presence => true

  belongs_to :user
  has_many :comments, -> { order(:created_at) }, :dependent => :destroy
  has_many :likes, :dependent => :destroy

  scope :featured, -> { where(:featured => true) }
  scope :popular, -> { where("views_count > 0").order("views_count DESC") }
  scope :newest, -> { order("created_at DESC") }

  scope(:newest_paginated, lambda do |page, per_page|
    newest.includes(:user).page(page).per(per_page)
  end)

  scope(:popular_paginated, lambda do |page, per_page|
    popular.includes(:user).page(page).per(per_page)
  end)

  before_create :assign_user, :unless => :user

  attr_accessible :title, :description, :time_compression

  def self.assign_user(user_token, user)
    where(:user_id => nil, :user_token => user_token).
    update_all(:user_id => user.id, :user_token => nil)
  end

  def self.cache_key
    timestamps = scoped.select(:updated_at).map { |o| o.updated_at.to_i }
    Digest::MD5.hexdigest timestamps.join('/')
  end

  def assign_user
    if user_token.present?
      if ut = UserToken.find_by_token(user_token)
        self.user = ut.user
        self.user_token = nil
      end
    end
  end

  def update_snapshot(snapshot)
    self.snapshot = snapshot
    save!
  end

  def stdout
    @stdout ||= Stdout.new(stdout_data, stdout_timing)
  end

end
