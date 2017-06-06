require 'open3'

class Terminal

  SCRIPT_PATH = (Rails.root + "vt" + "main.js").to_s

  def initialize(width, height)
    @process = Process.new("node #{SCRIPT_PATH}")
    send_cmd("new", { width: width, height: height })
  end

  def feed(data)
    send_cmd("feed-str", { str: data })
  end

  def screen
    send_cmd("dump-screen")
    screen = read_result
    lines = screen.fetch("lines")
    cursor = screen.fetch("cursor")

    {
      snapshot: Snapshot.build(lines),
      cursor: Cursor.new(cursor['x'], cursor['y'], cursor['visible'])
    }
  end

  def release
    process.stop
  end

  private

  def send_cmd(cmd, data = {})
    json = data.merge({ cmd: cmd }).to_json
    process.write("#{json}\n")
  end

  def read_result()
    Yajl::Parser.new.parse(process.read_line).fetch("result")
  end

  attr_reader :process

  class Process

    def initialize(command)
      @stdin, @stdout, @thread = Open3.popen2(command)
    end

    def write(data)
      check_thread!
      @stdin.write(data)
    end

    def read_line
      check_thread!
      @stdout.readline.strip
    end

    def stop
      @stdin.close
    end

    private

    def check_thread!
      raise "terminal died, exit code: #{@thread.value.exitstatus}, signaled?: #{@thread.value.signaled?}" unless @thread.alive?
    end
  end

end
