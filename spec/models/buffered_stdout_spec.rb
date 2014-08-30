require 'rails_helper'

describe BufferedStdout do

  let(:stdout) { described_class.new('spec/fixtures/high-freq-stdout',
                                     'spec/fixtures/high-freq-stdout.time') }

  describe '#each' do
    let(:yield_args) { [
      [0.016666, 'abcde'],
      [1.000000, 'f'],
      [0.016665, 'g'],
      [0.016666, 'hi'],
      [0.000002, 'j'],
      [0.016666, 'k'],
      [0.016667, 'l'],
      [0.000001, 'm']
    ] }

    it 'yields for each frame with delay and data at 60hz freq tops' do
      expect { |b| stdout.each(&b) }.to yield_successive_args(*yield_args)
    end
  end

end
