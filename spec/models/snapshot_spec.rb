require 'rails_helper'

describe Snapshot do

  let(:snapshot) { described_class.build(data) }
  let(:data) { [
    [['a',  fg: 1], ['b', fg: 2]],
    [['ab', fg: 3]              ],
    [['a',  fg: 5], ['b', fg: 6]],
    [[' ',  {}]   , ['' , {}]]
  ] }

  describe '#thumbnail' do
    let(:thumbnail) { snapshot.thumbnail(1, 2) }

    it 'returns a thumbnail of requested width' do
      expect(thumbnail.width).to eq(1)
    end

    it 'returns a thumbnail of requested height' do
      expect(thumbnail.height).to eq(2)
    end

    it 'crops the grid at the bottom left corner' do
      expect(thumbnail.as_json).to eq([
        [['a', fg: 3]],
        [['a', fg: 5]]
      ])
    end
  end

end
