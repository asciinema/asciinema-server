require 'spec_helper'

describe AsciicastDecorator do
  describe '#os' do
    it 'returns "unknown" when uname is blank' do
      asciicast = Asciicast.new
      asciicast.uname = nil
      decorated_asciicast = AsciicastDecorator.new(asciicast)
      decorated_asciicast.os.should == 'unknown'
    end
  end
end
