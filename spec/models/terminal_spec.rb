require 'spec_helper'

describe Terminal do

  let(:terminal) { Terminal.new(20, 10) }
  let(:tsm_screen) { double('tsm_screen', :draw => nil) }
  let(:tsm_vte) { double('tsm_vte', :input => nil) }
  let(:snapshot) { double('snapshot') }

  before do
    allow(TSM::Screen).to receive(:new).with(20, 10) { tsm_screen }
    allow(TSM::Vte).to receive(:new).with(tsm_screen) { tsm_vte }
    allow(Snapshot).to receive(:build).with([:array]) { snapshot }
  end

  describe '#feed' do
    subject { terminal.feed('foo') }

    it 'feeds the vte with the data' do
      subject

      expect(tsm_vte).to have_received(:input).with('foo')
    end

    it "groups the characters by line and attributes" do
      expect(tsm_screen).to receive(:draw).
        and_yield(0, 0, 'f', { :fg => 1 }).
        and_yield(1, 0, 'o', { :fg => 1 }).
        and_yield(0, 1, 'o', { :fg => 1 }).
        and_yield(1, 1, 'b', { :fg => 2 })

      expect(subject).to eq([
        [['fo', { :fg => 1 }]],
        [['o', { :fg => 1 }], ['b', { :fg => 2 }]]
      ])
    end
  end

end
