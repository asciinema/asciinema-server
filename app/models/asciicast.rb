class Asciicast < ActiveRecord::Base
  mount_uploader :stdin, BasicUploader
  mount_uploader :stdin_timing, BasicUploader
  mount_uploader :stdout, BasicUploader
  mount_uploader :stdout_timing, BasicUploader

  validates :stdout, :stdout_timing, :presence => true
  validates :terminal_columns, :terminal_lines, :duration, :presence => true

  has_many :comments, :order => :created_at

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

  def as_json(opts = {})
    super :methods => [:escaped_stdout_data, :stdout_timing_data]
  end

  def escaped_stdout_data
    if data = stdout.read
      data.bytes.map { |b| '\x' + format('%02x', b) }.join
    else
      nil
    end
  end

  def stdout_timing_data
    if data = stdout_timing.read
      Bzip2.uncompress(data).lines.map do |line|
        delay, n = line.split
        [delay.to_f, n.to_i]
      end
    else
      nil
    end
  end
end
