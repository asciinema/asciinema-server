require 'rails_helper'

describe Cursor do

  let(:cursor) { described_class.new(1, 2, true) }

  describe '#diff' do
    let(:other) { described_class.new(3, 4, false) }

    subject { cursor.diff(other) }

    it { should eq({ x: 1, y: 2, visible: true }) }

    context "when x is the same" do
      let(:other) { described_class.new(1, 4, false) }

      it 'skips x from the hash' do
        expect(subject).not_to have_key(:x)
      end
    end

    context "when y is the same" do
      let(:other) { described_class.new(3, 2, false) }

      it 'skips y from the hash' do
        expect(subject).not_to have_key(:y)
      end
    end

    context "when visible is the same" do
      let(:other) { described_class.new(3, 4, true) }

      it 'skips visible from the hash' do
        expect(subject).not_to have_key(:visible)
      end
    end

    context "when other is nil" do
      let(:other) { nil }

      it { should eq({ x: 1, y: 2, visible: true }) }
    end
  end

end
