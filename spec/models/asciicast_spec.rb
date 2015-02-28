require 'rails_helper'
require 'tempfile'

describe Asciicast do

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

  let(:asciicast) { described_class.new }

  describe '#user' do
    subject { asciicast.user }

    context "when it has user assigned" do
      let(:user) { User.new }

      before do
        asciicast.user = user
      end

      it { should be(user) }
    end

    context "when it doesn't have user assigned" do
      it 'is a null user' do
        expect(asciicast.user.temporary_username).to eq('anonymous')
      end
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
