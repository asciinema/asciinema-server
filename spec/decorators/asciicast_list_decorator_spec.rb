require 'spec_helper'

describe AsciicastListDecorator do

  let(:decorator) { described_class.new(list, 3, 10) }
  let(:list) { double('list', category: :foo, items: items) }
  let(:items) { double('items', paginate: paginated) }
  let(:paginated) { [Asciicast.new] }

  describe '#category_name' do
    subject { decorator.category_name }

    it { should eq('Foo asciicasts') }
  end

  describe '#items' do
    subject { decorator.items }

    it 'returns the items paginated' do
      expect(subject).to eq(paginated)
      expect(items).to have_received(:paginate).with(3, 10)
    end

    it 'wraps the paginated items in a PaginatingDecorator' do
      paginating_decorator = double('paginating_decorator')

      allow(PaginatingDecorator).to receive(:new).
        with(paginated) { paginating_decorator }

      expect(subject).to be(paginating_decorator)
    end
  end

end
