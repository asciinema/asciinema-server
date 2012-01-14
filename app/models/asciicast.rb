class Asciicast < ActiveRecord::Base
  mount_uploader :stdin, BasicUploader
  mount_uploader :stdin_timing, BasicUploader
  mount_uploader :stdout, BasicUploader
  mount_uploader :stdout_timing, BasicUploader

  validates :stdout, :stdout_timing, :presence => true
  validates :terminal_columns, :terminal_lines, :duration, :presence => true

  def meta=(file)
    data = JSON.parse(file.tempfile.read)

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
end
