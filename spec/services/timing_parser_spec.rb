require 'rails_helper'

describe TimingParser do

  describe '.parse' do
    it 'returns array of arrays[delay, size]' do
      timing = TimingParser.parse("1.234 30\n56.55 100")
      expect(timing).to eq([[1.234, 30], [56.55, 100]])
    end
  end

end
