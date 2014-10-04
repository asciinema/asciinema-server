require 'rails_helper'

RSpec.describe ExpiringToken, :type => :model do

  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:token) }
  it { should validate_presence_of(:expires_at) }

  describe '.create_for_user' do
    it 'creates expiring token with generated token and expiration time in the future' do
      user = create(:user)

      expiring_token = ExpiringToken.create_for_user(user)

      expect(expiring_token.user).to eq(user)
      expect(expiring_token.token.size).to eq(22)
      expect(expiring_token.expires_at).to be > Time.now
    end
  end

  describe '.active_for_token' do
    it 'returns not used and not expired expiring token matching given token' do
      used_expiring_token = create(:used_expiring_token)
      expired_expiring_token = create(:expired_expiring_token)
      good_expiring_token = create(:expiring_token)

      expect(ExpiringToken.active_for_token(used_expiring_token.token)).to be(nil)
      expect(ExpiringToken.active_for_token(expired_expiring_token.token)).to be(nil)
      expect(ExpiringToken.active_for_token(good_expiring_token.token)).to eq(good_expiring_token)
    end
  end

  describe '#use!' do
    it 'sets used_at to the current time and saves the record' do
      expiring_token = create(:expiring_token)
      now = Time.now

      Timecop.freeze(now) do
        expiring_token.use!
      end

      expect(expiring_token.used_at).to eq(now)
      expect(expiring_token).to_not be_changed
    end
  end

end
