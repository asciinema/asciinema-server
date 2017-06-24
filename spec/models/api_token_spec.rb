require 'rails_helper'

describe ApiToken do

  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:token) }

  describe "uniqueness validation" do
    before do
      create(:api_token)
    end

    it { should validate_uniqueness_of(:token) }
  end

end
