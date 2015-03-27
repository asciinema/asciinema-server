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
  scope :latest_limited, -> (n) { by_recency.limit(n).includes(:user) }
  scope :random_featured_limited, -> (n) {
    featured.by_random.limit(n).includes(:user)
  }

  def self.cache_key
    timestamps = scoped.select(:updated_at).map { |o| o.updated_at.to_i }
    Digest::MD5.hexdigest timestamps.join('/')
  end

  def self.paginate(page, per_page)
    page(page).per(per_page)
  end

  def self.for_category_ordered(category, order, page = nil, per_page = nil)
    collection = all

    if category == :featured
      collection = collection.featured
    end

    collection = collection.order("#{ORDER_MODES[order]} DESC")

    if page
      collection = collection.paginate(page, per_page)
    end

    collection
  end

  def user
    super || self.user = User.null
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

end
