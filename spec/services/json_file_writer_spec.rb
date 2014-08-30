require 'rails_helper'

describe JsonFileWriter do

  let(:writer) { described_class.new }

  describe '#write_enumerable' do
    let(:file) { StringIO.new }
    let(:enumerable) { [item_1, item_2] }
    let(:item_1) { double('item_1', :to_json => 'a') }
    let(:item_2) { double('item_2', :to_json => 'b') }

    subject { writer.write_enumerable(file, enumerable) }

    before do
      subject
    end

    it 'writes the enumerable to the file in json format' do
      expect(file.string).to eq('[a,b]')
    end

    it 'closes the file' do
      expect(file).to be_closed
    end
  end

end
