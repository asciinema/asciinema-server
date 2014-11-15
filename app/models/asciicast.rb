class Asciicast < ActiveRecord::Base

  ORDER_MODES = { recency: 'created_at', popularity: 'views_count' }

  mount_uploader :stdin_data,    StdinDataUploader
  mount_uploader :stdin_timing,  StdinTimingUploader
  mount_uploader :stdout_data,   StdoutDataUploader
  mount_uploader :stdout_timing, StdoutTimingUploader
  mount_uploader :stdout_frames, StdoutFramesUploader
  mount_uploader :file, AsciicastUploader
  mount_uploader :image, ImageUploader

  serialize :snapshot, ActiveSupportJsonProxy

  belongs_to :user
  has_many :comments, -> { order(:created_at) }, dependent: :destroy
  has_many :likes, dependent: :destroy

  validates :user, :terminal_columns, :terminal_lines, :duration, presence: true
  validates :stdout_data, :stdout_timing, presence: true, unless: :file
  validates :file, presence: true, unless: :stdout_data
  validates :snapshot_at, numericality: { greater_than: 0, allow_blank: true }

  scope :featured, -> { where(featured: true) }
  scope :by_recency, -> { order("created_at DESC") }
  scope :by_random, -> { order("RANDOM()") }
  scope :non_private, -> { where(private: false) }
  scope :homepage_latest, -> { non_private.by_recency.limit(6).includes(:user) }
  scope :homepage_featured, -> { non_private.featured.by_random.limit(6).includes(:user) }

  before_create :generate_secret_token

  def self.cache_key
    timestamps = scoped.select(:updated_at).map { |o| o.updated_at.to_i }
    Digest::MD5.hexdigest timestamps.join('/')
  end

  def self.paginate(page, per_page)
    page(page).per(per_page)
  end

  def self.for_category_ordered(category, order, page = nil, per_page = nil)
    collection = self.non_private

    if category == :featured
      collection = collection.featured
    end

    collection = collection.order("#{ORDER_MODES.fetch(order)} DESC")

    if page
      collection = collection.paginate(page, per_page)
    end

    collection
  end

  def title=(value)
    value ? super(value.strip[0...255]) : super
  end

  def command=(value)
    value ? super(value.strip[0...255]) : super
  end

  def self.generate_secret_token
    SecureRandom.hex.to_i(16).to_s(36)
  end

  def stdout
    return @stdout if @stdout
    @stdout = Stdout::Buffered.new(get_stdout)
  end

  def with_terminal
    terminal = Terminal.new(terminal_columns, terminal_lines)
    yield(terminal)
  ensure
    terminal.release if terminal
  end

  def theme
    theme_name.presence && Theme.for_name(theme_name)
  end

  def image_filename
    "#{image_hash}.png"
  end

  def image_stale?
    !image.file || (image.file.filename != image_filename)
  end

  def owner?(user)
    user && self.user == user
  end

  private

  def get_stdout
    if version == 0
      Stdout::MultiFile.new(stdout_data.decompressed_path,
                            stdout_timing.decompressed_path)
    else
      Stdout::SingleFile.new(file.url)
    end
  end

  def image_hash
    version = 2 # version of screenshot, increment to force regeneration
    input = "#{version}/#{id}/#{snapshot_at}"
    Digest::SHA1.hexdigest(input)
  end

  def generate_secret_token
    begin
      self.secret_token = self.class.generate_secret_token
    end while self.class.exists?(secret_token: secret_token)
  end

end
