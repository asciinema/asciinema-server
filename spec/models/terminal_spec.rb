# encoding: utf-8

require 'rails_helper'

describe Terminal, needs_terminal_bin: true do

  let(:terminal) { Terminal.new(6, 3) }
  let(:first_line_text) { subject.as_json.first.map(&:first).join.strip }

  before do
    data.each do |chunk|
      terminal.feed(chunk)
    end
  end

  after do
    terminal.release
  end

  describe '#snapshot' do
    subject { terminal.snapshot }

    let(:data) { ["fo\e[31mo\e[42mba\n", "\rr\e[0mb\e[1;4;5;7maz"] }

    it 'returns an instance of Snapshot' do
      expect(subject).to be_kind_of(Snapshot)
    end

    it "returns screen cells groupped by the character attributes" do
      expect(subject.as_json).to eq([
        [
          ['fo', {}],
          ['o', fg: 1],
          ['ba', fg: 1, bg: 2],
          [' ', {}],
        ],
        [
          ['r', fg: 1, bg: 2],
          ['b', {}],
          ['az', bold: true, underline: true, inverse: true, blink: true],
          [' ', inverse: true],  # <- cursor here
          [' ', {}]
        ],
        [
          ['      ', {}]
        ]
      ])
    end

    describe 'utf-8 characters handling' do
      let(:terminal) { Terminal.new(20, 1) }

      context "when polish national characters given" do
        let(:data) { ['żółć'] }

        it 'returns proper utf-8 string' do
          expect(first_line_text).to eq('żółć')
        end
      end

      context "when chinese national characters given" do
        let(:data) { ['雞機基積'] }

        it 'returns proper utf-8 string' do
          expect(first_line_text).to eq('雞機基積')
        end
      end
    end

    context "when invalid utf-8 character is yielded by tsm_screen" do
      let(:terminal) { Terminal.new(3, 1) }
      let(:data) { ["A\xc3\xff\xaaZ"] }

      it 'gets replaced with "�"' do
        expect(first_line_text).to eq('A�Z')
      end
    end

    context "when double quote character ...." do
      let(:terminal) { Terminal.new(6, 1) }
      let(:data) { ['"a"b"'] }

      it 'works' do
        expect(first_line_text).to eq('"a"b"')
      end
    end

    context "when backslash character..." do
      let(:terminal) { Terminal.new(6, 1) }
      let(:data) { ['a\\b'] }

      it 'works' do
        expect(first_line_text).to eq('a\\b')
      end
    end

    describe 'with a 256-color mode foreground color' do
      subject { terminal.snapshot.as_json.first.first.last[:fg] }

      let(:data) { ["\x1b[38;5;#{color_code}mX"] }

      (1..255).each do |n|
        context "of value #{n}" do
          let(:color_code) { n }

          it { should eq(n) }
        end
      end
    end

    describe 'with a 256-color mode background color' do
      subject { terminal.snapshot.as_json.first.first.last[:bg] }

      let(:data) { ["\x1b[48;5;#{color_code}mX"] }

      (1..255).each do |n|
        context "of value #{n}" do
          let(:color_code) { n }

          it { should eq(n) }
        end
      end
    end
  end

  describe '#cursor' do
    subject { terminal.cursor }

    let(:data) { ["foo\n\rba"] }

    it 'gets its x position from the screen' do
      expect(subject.x).to eq(2)
    end

    it 'gets its y position from the screen' do
      expect(subject.y).to eq(1)
    end

    it 'gets its visibility from the screen' do
      expect(subject.visible).to eq(true)
    end

    context "when cursor was hidden" do
      before do
        terminal.feed("\e[?25l")
      end

      it 'gets its visibility from the screen' do
        expect(subject.visible).to eq(false)
      end
    end
  end

end
