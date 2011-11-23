class Asciicast < ActiveRecord::Base
  validates :terminal_columns, :terminal_lines, :duration, :presence => true

  mount_uploader :stdin, BasicUploader
  mount_uploader :stdin_timing, BasicUploader
  mount_uploader :stdout, BasicUploader
  mount_uploader :stdout_timing, BasicUploader
end
