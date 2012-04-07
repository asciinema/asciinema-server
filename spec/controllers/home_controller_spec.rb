require 'spec_helper'

describe HomeController do

  describe "GET 'show'" do
    describe 'when there is at least one featured cast' do
      before do
        Factory(:asciicast, :featured => true)
      end

      it "returns http success" do
        get 'show'
        response.should be_success
      end
    end

    describe 'when there is no featured cast but any cast exists' do
      before do
        Factory(:asciicast, :featured => false)
      end

      it "returns http success" do
        get 'show'
        response.should be_success
      end
    end

    describe 'when there are no casts at all' do
      it "returns http success" do
        get 'show'
        response.should be_success
      end
    end
  end

end
