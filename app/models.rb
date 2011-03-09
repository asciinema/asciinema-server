class Movie
  include DataMapper::Resource
  include Paperclip::Resource

  property :id, Serial

  property :name, String

  property :typescript_file_name, String, :required => true, :length => 256
  property :typescript_content_type, String, :length => 128
  property :typescript_file_size, Integer
  property :typescript_updated_at, DateTime

  property :timing_file_name, String, :required => true, :length => 256
  property :timing_content_type, String, :length => 128
  property :timing_file_size, Integer
  property :timing_updated_at, DateTime

  property :terminal_type, String
  property :terminal_cols, Integer, :required => true
  property :terminal_lines, Integer, :required => true

  timestamps :at

  has_attached_file :typescript, :path => "#{APP_ROOT}/public/system/:attachment/:id"
  has_attached_file :timing, :path => "#{APP_ROOT}/public/system/:attachment/:id"

  validates_attachment_presence :typescript
  validates_attachment_presence :timing
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{File.expand_path(File.join(APP_ROOT, 'db', 'db.sqlite3'))}")
