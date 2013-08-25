require 'spec_helper'

describe Snapshot do

  let(:snapshot) { described_class.new(data) }

  let(:data) { [
    [['a', fg: 1], ['b', fg: 2], ['c', fg: 3]],
    [['d', fg: 4], ['e', fg: 5], ['f', fg: 6]],
    [['g', bg: 1], ['h', bg: 2], ['i', bg: 3]],
    [[' ', {}   ], ['k', bg: 5], ['l', bg: 6]],
    [[' ', {}   ], [' ', {}   ], [' ', {}   ]]
  ] }

  describe '#width' do
    subject { snapshot.width }

    it { should eq(3) }
  end

  describe '#height' do
    subject { snapshot.height }

    it { should eq(5) }
  end

  describe '#cell' do
    subject { snapshot.cell(column, line) }

    context "at 0,0" do
      let(:column) { 0 }
      let(:line)   { 0 }

      it { should eq(Cell.new('a', Brush.new(fg: 1))) }
    end

    context "at 1,2" do
      let(:column) { 1 }
      let(:line)   { 2 }

      it { should eq(Cell.new('h', Brush.new(bg: 2))) }
    end

    context "at 2,3" do
      let(:column) { 2 }
      let(:line)   { 3 }

      it { should eq(Cell.new('l', Brush.new(bg: 6))) }
    end
  end

  describe '#thumbnail' do

    def thumbnail_text(thumbnail)
      ''.tap do |text|
        0.upto(thumbnail.height - 1) do |line|
          0.upto(thumbnail.width - 1) do |column|
            text << thumbnail.cell(column, line).text
          end
          text << "\n"
        end
      end
    end

    let(:height) { 3 }
    let(:thumbnail) { snapshot.thumbnail(2, height) }
    let(:text) { thumbnail_text(thumbnail) }

    it 'is a snapshot of requested width' do
      expect(thumbnail.width).to eq(2)
    end

    it 'is a snapshot of requested height' do
      expect(thumbnail.height).to eq(3)
    end

    context "when height is 3" do
      let(:height) { 3 }

      it 'returns thumbnail with 2nd, 3rd and 4th line cropped' do
        expect(text).to eq("de\ngh\n k\n")
      end
    end

    context "when height is 5" do
      let(:height) { 5 }

      it 'returns thumbnail with all the lines cropped' do
        expect(text).to eq("ab\nde\ngh\n k\n  \n")
      end
    end

    context "when height is 6" do
      let(:height) { 6 }

      it 'returns thumbnail with all the lines cropped + 1 empty line' do
        expect(text).to eq("ab\nde\ngh\n k\n  \n  \n")
      end
    end
  end

end
