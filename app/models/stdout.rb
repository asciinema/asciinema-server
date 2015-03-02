require 'open-uri'

class Stdout
  include Enumerable

  class SingleFile < self
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def each(&blk)
      open(path, 'r') do |f|
        Oj.sc_parse(FrameIterator.new(blk), f)
      end
    end

    class FrameIterator < ::Oj::ScHandler

      def initialize(callback)
        @callback = callback
      end

      def array_start
        if @top # we're already inside top level array
          [] # <- this will hold pair [delay, data]
        else
          @top = []
        end
      end

      def array_append(a, v)
        if a.equal?(@top)
          @callback.call(*v)
        else
          a << v
        end
      end

    end

  end

  class MultiFile < self
    attr_reader :data_path, :timing_path

    def initialize(data_path, timing_path)
      @data_path = data_path
      @timing_path = timing_path
    end

    def each
      File.open(data_path, 'rb') do |file|
        File.foreach(timing_path) do |line|
          yield(*delay_and_data_for_line(file, line))
        end
      end
    end

    private

    def delay_and_data_for_line(file, line)
      delay, size = TimingParser.parse_line(line)
      data = file.read(size).to_s.force_encoding('utf-8')

      [delay, data]
    end

  end

  class Buffered < self
    MIN_FRAME_LENGTH = 1.0 / 60

    attr_reader :stdout

    def initialize(stdout)
      @stdout = stdout
    end

    def each
      buffered_delay, buffered_data = 0.0, []

      stdout.each do |delay, data|
        if buffered_delay + delay < MIN_FRAME_LENGTH || buffered_data.empty?
          buffered_delay += delay
          buffered_data << data
        else
          yield(buffered_delay, buffered_data.join)
          buffered_delay = delay
          buffered_data = [data]
        end
      end

      yield(buffered_delay, buffered_data.join) unless buffered_data.empty?
    end

  end

end
