# encoding: utf-8

require 'spec_helper'

describe Stdout do
  let(:stdout) { Stdout.new('spec/fixtures/stdout.decompressed',
                            'spec/fixtures/stdout.time.decompressed') }

  describe '#each' do
    it 'yields for each frame with delay and data' do
      expect { |b| stdout.each(&b) }.
        to yield_successive_args([0.5, 'foobar'],
                                 [1.0, "bazqux\xC5"],
                                 [2.0, "\xBCółć"])
    end
  end

  describe '#each_until' do
    it 'yields for each frame with delay and data until <seconds>' do
      expect { |b| stdout.each_until(1.7, &b) }.
        to yield_successive_args([0.5, 'foobar'], [1.0, "bazqux\xC5"])
    end
  end

end
