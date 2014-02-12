# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:uid) { |n| n }
  sequence(:username) { |n| "user#{n}" }

  factory :user do
    provider "twitter"
    uid
    sequence(:username) { generate(:username) }
    sequence(:email) { |n| "foo#{n}@bar.com" }
    name nil
    avatar_url nil
  end

  factory :dummy_user, class: User do
    dummy true
    sequence(:username) { generate(:username) }
  end
end
