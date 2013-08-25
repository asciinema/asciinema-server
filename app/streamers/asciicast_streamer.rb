class AsciicastStreamer

  delegate :each, :to => :json_streamer

  def initialize(asciicast)
    build_json_streamer(asciicast)
  end

  private

  attr_reader :json_streamer

  def build_json_streamer(asciicast)
    attributes = attributes_for_streaming(asciicast)
    @json_streamer = JsonStreamer.new(attributes)
  end

  def attributes_for_streaming(asciicast)
    attributes = AsciicastSerializer.new(asciicast).as_json
    saved_time = prepare_stdout(attributes, asciicast)
    prepare_duration(attributes, asciicast, saved_time)

    attributes
  end

  def prepare_stdout(attributes, asciicast)
    saved_time = 0

    attributes['stdout'] = lambda do |&blk|
      blk.call('[')

      asciicast.stdout.each do |delay, frame_bytes|
        if asciicast.time_compression && delay > Asciicast::MAX_DELAY
          saved_time += (delay - Asciicast::MAX_DELAY)
          delay = Asciicast::MAX_DELAY
        end

        blk.call(%([#{delay},#{frame_bytes.bytes.to_a}],))
      end

      blk.call('[]]')
    end

    saved_time
  end

  def prepare_duration(attributes, asciicast, saved_time)
    attributes['duration'] = lambda do |&blk|
      blk.call(asciicast.duration - saved_time)
    end
  end

end
