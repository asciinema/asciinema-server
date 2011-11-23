class Asciicast < ActiveRecord::Base
  mount_uploader :stdin, BasicUploader
  mount_uploader :stdin_timing, BasicUploader
  mount_uploader :stdout, BasicUploader
  mount_uploader :stdout_timing, BasicUploader

  validates :stdout, :stdout_timing, :presence => true
  validates :terminal_columns, :terminal_lines, :duration, :presence => true
end
