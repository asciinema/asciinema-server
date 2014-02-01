require 'spec_helper'

describe BrowsePagePresenter do

  describe '.build' do
    subject { described_class.build(category, order, page, per_page) }

    let(:category) { 'awesome' }
    let(:order) { 'awesomeness' }
    let(:page) { 2 }
    let(:per_page) { 5 }

    it "builds presenter with given category symbolized" do
      expect(subject.category).to eq(:awesome)
    end

    context "when category is nil" do
      let(:category) { nil }

      it "builds presenter with category defaulting to DEFAULT_CATEGORY" do
        expect(subject.category).to eq(described_class::DEFAULT_CATEGORY)
      end
    end

    it "builds presenter with given order symbolized" do
      expect(subject.order).to eq(:awesomeness)
    end

    context "when order is nil" do
      let(:order) { nil }

      it "builds presenter with order defaulting to DEFAULT_ORDER" do
        expect(subject.order).to eq(described_class::DEFAULT_ORDER)
      end
    end

    it "builds presenter with given page" do
      expect(subject.page).to eq(2)
    end

    context "when page is nil" do
      let(:page) { nil }

      it "builds presenter with page = 1" do
        expect(subject.page).to eq(1)
      end
    end

    it "builds presenter with given per_page" do
      expect(subject.per_page).to eq(5)
    end

    context "when per_page is nil" do
      let(:per_page) { nil }

      it "builds presenter with per_page = PER_PAGE" do
        expect(subject.per_page).to eq(described_class::PER_PAGE)
      end
    end
  end

  let(:presenter) { described_class.new(category, order, page, per_page) }
  let(:category) { :awesome }
  let(:order) { :awesomeness }
  let(:page) { 2 }
  let(:per_page) { 5 }

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
