require 'spec_helper'

describe ViewCounter do
  let(:view_counter) { ViewCounter.new(asciicast, storage) }
  let(:asciicast) { create(:asciicast) }
  let(:storage) { {} }

  describe '#increment' do
    context "when called for the first time" do
      it "increments the views_count" do
        expect { view_counter.increment }.
          to change(asciicast, :views_count).by(1)
      end
    end

    context "when called for the second time" do
      before do
        view_counter.increment
      end

      it "doesn't increment the views_count" do
        expect { view_counter.increment }.
          not_to change(asciicast, :views_count)
      end
    end
  end
end
