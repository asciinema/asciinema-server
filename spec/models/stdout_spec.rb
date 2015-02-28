# encoding: utf-8

require 'rails_helper'

describe Stdout::MultiFile do
  let(:stdout) { Stdout::MultiFile.new('spec/fixtures/stdout.decompressed',
                                       'spec/fixtures/stdout.time.decompressed') }

  describe '#each' do
    it 'yields for each frame with delay and data' do
      expect { |b| stdout.each(&b) }.
        to yield_successive_args([0.5, 'foobar'],
                                 [1.0, "bazqux\xC5"],
                                 [2.0, "\xBCółć"])
    end
  end

end

describe Stdout::SingleFile do
  let(:stdout) { Stdout::SingleFile.new('spec/fixtures/1/asciicast.json') }

  describe '#each' do
    it 'yields for each frame with delay and data' do
      expect { |b| stdout.each(&b) }.
        to yield_successive_args([1.234567, 'foo bar'],
                                 [5.678987, 'baz qux'],
                                 [3.456789, 'żółć jaźń'])
    end
  end

end

describe Stdout::Buffered do
  let(:inner) { double('inner') }
  let(:stdout) { Stdout::Buffered.new(inner) }

  before do
    allow(inner).to receive(:each)
      .and_yield(0.200000, '!')
      .and_yield(0.010000, 'a')
      .and_yield(0.006000, 'b')
      .and_yield(0.000600, 'c')
      .and_yield(0.000060, 'd')
      .and_yield(0.000006, 'e')
      .and_yield(1.000000, 'f')
      .and_yield(0.016665, 'g')
      .and_yield(0.000002, 'h')
      .and_yield(0.016664, 'i')
      .and_yield(0.000002, 'j')
      .and_yield(0.016666, 'k')
      .and_yield(0.016667, 'l')
      .and_yield(0.000001, 'm')
  end

  describe '#each' do
    let(:yield_args) { [
      [0.200000, '!'],
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
