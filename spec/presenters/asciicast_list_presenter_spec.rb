require 'spec_helper'

describe AsciicastListPresenter do

  let(:presenter) { described_class.new(category, order, page, per_page) }
  let(:category) { 'awesome' }
  let(:order) { 'awesomeness' }
  let(:page) { 2 }
  let(:per_page) { 5 }

  describe '#category' do
    subject { presenter.category }

    let(:category) { nil }

    it "defaults to :all" do
      expect(subject).to eq(:all)
    end
  end

  describe '#order' do
    subject { presenter.order }

    let(:order) { nil }

    it "defaults to :recency" do
      expect(subject).to eq(:recency)
    end
  end

  describe '#page' do
    subject { presenter.page }

    let(:page) { nil }

    it "defaults to 1" do
      expect(subject).to eq(1)
    end
  end

  describe '#category_name' do
    subject { presenter.category_name }

    it { should eq('Awesome asciicasts') }
  end

  describe '#items' do
    subject { presenter.items }

    let(:collection) { [asciicast] }
    let(:asciicast) { double('asciicast', decorate: double(title: 'quux')) }

    before do
      allow(Asciicast).to receive(:for_category_ordered) { collection }
    end

    it "gets the asciicasts for given category, order, page and per_page" do
      subject

      expect(Asciicast).to have_received(:for_category_ordered).
        with(:awesome, :awesomeness, 2, 5)
    end

    it "wraps the asciicasts with paginating decorator" do
      expect(subject).to respond_to(:current_page)
      expect(subject).to respond_to(:total_pages)
      expect(subject).to respond_to(:limit_value)
      expect(subject.first.title).to eq('quux')
    end
  end

end
