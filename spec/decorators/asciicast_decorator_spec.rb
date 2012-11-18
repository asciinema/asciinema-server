require 'spec_helper'

describe AsciicastDecorator do
  before { ApplicationController.new.set_current_view_context }

  describe '#os' do
    it 'returns "unknown" when uname is blank' do
      asciicast = Asciicast.new
      asciicast.uname = nil
      decorated_asciicast = AsciicastDecorator.new(asciicast)
      decorated_asciicast.os.should == 'unknown'
    end
  end
end
