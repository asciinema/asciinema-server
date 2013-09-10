require 'spec_helper'

describe FrameDiff do

  let(:frame_diff) { described_class.new(line_changes, cursor_changes) }
  let(:line_changes) { { 0 => line_0, 2 => line_2 } }
  let(:cursor_changes) { { x: 1 } }
  let(:line_0) { double('line_0') }
  let(:line_2) { double('line_2') }
  let(:line_optimizer) { double('line_optimizer') }
  let(:optimized_line_0) { double('optimized_line_0') }
  let(:optimized_line_2) { double('optimized_line_2') }

  describe '#as_json' do
    subject { frame_diff.as_json }

    before do
      allow(LineOptimizer).to receive(:new) { line_optimizer }
      allow(line_optimizer).to receive(:optimize).
        with(line_0) { optimized_line_0 }
      allow(line_optimizer).to receive(:optimize).
        with(line_2) { optimized_line_2 }
    end

    it 'includes line changes and cursor changes' do
      expect(subject).to eq({ :lines => { 0 => optimized_line_0,
                                          2 => optimized_line_2 },
                              :cursor => cursor_changes })
    end

    context "when there are no line changes" do
      let(:line_changes) { {} }

      it 'skips the lines hash' do
        expect(subject).not_to have_key(:lines)
      end
    end

    context "when there are no cursor changes" do
      let(:cursor_changes) { {} }

      it 'skips the cursor hash' do
        expect(subject).not_to have_key(:cursor)
      end
    end
  end

end
