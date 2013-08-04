# encoding: utf-8

require 'spec_helper'

describe Stdout do
  let(:stdout) { Stdout.new(data, timing) }
  let(:data) { 'foobarbazquxżółć' }
  let(:timing) { [[0.5, 6], [1.0, 7], [2.0, 7]] }

  describe '#bytes_until' do
    subject { stdout.bytes_until(1.7) }

    it { should eq([102, 111, 111, 98, 97, 114, 98, 97, 122, 113, 117, 120, 197]) }
  end

  describe '#each' do
    it 'yields for each frame with delay and frame bytes' do
      frames = []
      stdout.each do |delay, bytes|
        frames << [delay, bytes]
      end

      expect(frames[0][0]).to eq(0.5)
      expect(frames[0][1]).to eq([102, 111, 111, 98, 97, 114])

      expect(frames[1][0]).to eq(1.0)
      expect(frames[1][1]).to eq([98, 97, 122, 113, 117, 120, 197])

      expect(frames[2][0]).to eq(2.0)
      expect(frames[2][1]).to eq([188, 195, 179, 197, 130, 196, 135])
    end
  end
end
