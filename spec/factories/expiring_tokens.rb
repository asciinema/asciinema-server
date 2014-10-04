# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :expiring_token do
    association :user
    sequence(:token) { |n| "token-#{n}" }
    expires_at { 10.minutes.from_now }
  end

  factory :used_expiring_token, parent: :expiring_token do
    used_at { 1.minute.ago }
  end

  factory :expired_expiring_token, parent: :expiring_token do
    expires_at { 1.minute.ago }
  end
end
