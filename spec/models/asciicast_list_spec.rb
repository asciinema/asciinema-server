require 'spec_helper'

describe AsciicastList do

  let(:list) { described_class.new(category, order, repository) }

  let(:category) { 'featured' }
  let(:order) { 'recency' }
  let(:repository) { double('repository') }

  describe '#category' do
    subject { list.category }

    context "when it was passed as a string" do
      let(:category) { 'thecat' }

      it { should eq(:thecat) }
    end

    context "when it was passed as nil" do
      let(:category) { nil }

      it { should eq(:all) }
    end
  end

  describe '#order' do
    subject { list.order }

    context "when it was passed as a string" do
      let(:order) { 'thecat' }

      it { should eq(:thecat) }
    end

    context "when it was passed as nil" do
      let(:order) { nil }

      it { should eq(:recency) }
    end
  end

  describe '#items' do
    subject { list.items }

    let(:category) { 'foo' }
    let(:order) { 'bar' }
    let(:asciicasts) { [Asciicast.new] }

    before do
      allow(repository).to receive(:for_category_ordered) { asciicasts }
      subject
    end

    it { should eq(asciicasts) }

    it 'calls for_category_ordered on repository with proper args' do
      expect(repository).to have_received(:for_category_ordered).
        with(:foo, :bar)
    end
  end

end
