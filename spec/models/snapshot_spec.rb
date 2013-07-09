require 'spec_helper'

describe Snapshot do

  describe '#==' do
    let(:snapshot) { Snapshot.new([:foo]) }

    subject { snapshot == other }

    context "when the other has the same lines" do
      let(:other) { Snapshot.new([:foo]) }

      it { should be(true) }
    end

    context "when the other has a different lines" do
      let(:other) { Snapshot.new([:foo, :bar]) }

      it { should be(false) }
    end
  end

end
