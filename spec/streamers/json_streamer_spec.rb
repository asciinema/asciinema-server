require 'spec_helper'

describe JsonStreamer do

  let(:streamer) { JsonStreamer.new(object) }
  let(:object) { {
    :foo => 'bar',
    'baz' => 1337,
    'qux' => true,
    'arr' => [1, 2],
    'blk' => lambda { |&blk| blk['12.']; blk[3] }
  } }

  describe '#each' do
    it 'calls supplied block with each key value pair' do
      expect { |b| streamer.each(&b) }.
        to yield_successive_args(
          '{',
            '"foo":', '"bar"', ',',
            '"baz":', '1337' , ',',
            '"qux":', 'true' , ',',
            '"arr":', '[1,2]', ',',
            '"blk":', '12.'  , '3',
          '}')
    end
  end

end
