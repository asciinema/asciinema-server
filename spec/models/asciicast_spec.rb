require 'rails_helper'
require 'tempfile'

describe Asciicast do

  describe '.find_by_id_or_secret_token!' do
    subject { Asciicast.find_by_id_or_secret_token!(thing) }

    context 'for public asciicast' do
      let(:asciicast) { create(:asciicast, private: false) }

      context 'when looked up by id' do
        let(:thing) { asciicast.id }

        it { should eq(asciicast) }
      end

      context 'when looked up by secret token' do
        let(:thing) { asciicast.secret_token }

        it { should eq(asciicast) }
      end
    end

    context 'for private asciicast' do
      let(:asciicast) { create(:asciicast, private: true) }

      context 'when looked up by id' do
        let(:thing) { asciicast.id }

        it 'raises RecordNotFound' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when looked up by secret token' do
        let(:thing) { asciicast.secret_token }

        it { should eq(asciicast) }
      end
    end
  end

  describe '.for_category_ordered' do
    subject { described_class.for_category_ordered(category, order) }

    let!(:asciicast_1) { create(:asciicast, created_at:  2.hours.ago,
                                            views_count: 10,
                                            featured:    false) }
    let!(:asciicast_2) { create(:asciicast, created_at:  1.hour.ago,
                                            views_count: 20,
                                            featured:    true) }
    let!(:asciicast_3) { create(:asciicast, created_at:  4.hours.ago,
                                            views_count: 30,
                                            featured:    false) }
    let!(:asciicast_4) { create(:asciicast, created_at:  3.hours.ago,
                                            views_count: 40,
                                            featured:    true) }

    context "when category is :all" do
      let(:category) { :all }

      context "and order is :recency" do
        let(:order) { :recency }

        it { should eq([asciicast_2, asciicast_1, asciicast_4, asciicast_3]) }
      end

      context "and order is :popularity" do
        let(:order) { :popularity }

        it { should eq([asciicast_4, asciicast_3, asciicast_2, asciicast_1]) }
      end
    end

    context "when category is :featured" do
      let(:category) { :featured }

      context "and order is :recency" do
        let(:order) { :recency }

        it { should eq([asciicast_2, asciicast_4]) }
      end

      context "and order is :popularity" do
        let(:order) { :popularity }

        it { should eq([asciicast_4, asciicast_2]) }
      end
    end
  end

  describe '#to_param' do
    subject { asciicast.to_param }

    let(:asciicast) { Asciicast.new(id: 123, secret_token: 'sekrit') }

    context 'for public asciicast' do
      before do
        asciicast.private = false
      end

      it { should eq('123') }
    end

    context 'for private asciicast' do
      before do
        asciicast.private = true
      end

      it { should eq('sekrit') }
    end
  end

  describe '#stdout' do
    context 'for single-file, JSON asciicast' do
      let(:asciicast) { create(:asciicast) }

      subject { asciicast.stdout.to_a }

      it 'is enumerable with [delay, data] pair as every item' do
        expect(subject).to eq([
          [1.234567, "foo bar"],
          [5.678987, "baz qux"],
          [3.456789, "żółć jaźń"],
        ])
      end
    end

    context 'for multi-file, legacy asciicast' do
      let(:asciicast) { create(:legacy_asciicast) }

      subject { asciicast.stdout.to_a }

      it 'is enumerable with [delay, data] pair as every item' do
        expect(subject).to eq([
          [1.234567, "foobar"],
          [0.123456, "baz"],
          [2.345678, "qux"],
        ])
      end
    end
  end

  describe '#theme' do
    it 'returns proper theme when theme_name is not blank' do
      asciicast = described_class.new(theme_name: 'tango')

      expect(asciicast.theme.name).to eq('tango')
    end

    it 'returns nil when theme_name is blank' do
      asciicast = described_class.new(theme_name: '')

      expect(asciicast.theme).to be(nil)
    end
  end

end
