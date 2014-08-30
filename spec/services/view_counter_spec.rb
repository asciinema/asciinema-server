require 'rails_helper'

describe ViewCounter do
  let(:view_counter) { described_class.new }

  describe '#increment' do
    let(:asciicast) { create(:asciicast) }
    let(:storage) { {} }

    subject { view_counter.increment(asciicast, storage) }

    context "when called for the first time" do
      it "increments the views_count" do
        expect { subject }.to change(asciicast, :views_count).by(1)
      end
    end

    context "when called for the second time" do
      before do
        subject
      end

      it "doesn't increment the views_count" do
        expect { subject }.not_to change(asciicast, :views_count)
      end
    end
  end
end
