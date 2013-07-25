require 'spec_helper'

describe Snapshot do

  describe '#==' do
    let(:snapshot) { Snapshot.new([:foo]) }

    subject { snapshot == other }

    context "when the other has the same lines" do
      let(:other) { Snapshot.new([:foo]) }

      it { should be(true) }
    end

    context "when the other has a different lines" do
      let(:other) { Snapshot.new([:foo, :bar]) }

      it { should be(false) }
    end
  end

  describe '#crop' do
    let(:snapshot) { Snapshot.new(lines) }
    let(:lines) { [line_1, line_2, line_3] }
    let(:line_1) { double('line_1', :crop => cropped_line_1) }
    let(:line_2) { double('line_2', :crop => cropped_line_2) }
    let(:line_3) { double('line_3', :crop => cropped_line_3) }
    let(:cropped_line_1) { double('cropped_line_1') }
    let(:cropped_line_2) { double('cropped_line_2') }
    let(:cropped_line_3) { double('cropped_line_3') }
    let(:width) { 3 }

    subject { snapshot.crop(width, height) }

    context "when height is lower than lines count" do
      let(:height) { 2 }

      it 'crops the last "height" lines' do
        subject

        expect(line_1).to_not have_received(:crop)
        expect(line_2).to have_received(:crop).with(3)
        expect(line_3).to have_received(:crop).with(3)
      end

      it 'returns a new Snapshot with last 2 lines cropped' do
        expect(subject).to eq(Snapshot.new([cropped_line_2, cropped_line_3]))
      end
    end

    context "when height is equal to lines count" do
      let(:height) { 3 }

      it 'returns a new Snapshot with all lines cropped' do
        expect(subject).to eq(Snapshot.new([cropped_line_1, cropped_line_2,
                                            cropped_line_3]))
      end
    end

    context "when height is greater than lines count" do
      let(:height) { 4 }

      it 'returns a new Snapshot with all lines cropped' do
        expect(subject).to eq(Snapshot.new([cropped_line_1, cropped_line_2,
                                            cropped_line_3]))
      end
    end
  end
end
