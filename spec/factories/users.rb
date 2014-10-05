# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:uid) { |n| n }
  sequence(:username) { |n| "user#{n}" }

  factory :user do
    provider "twitter"
    uid
    sequence(:username) { generate(:username) }
    sequence(:email) { |n| "foo#{n}@bar.com" }
  end

  factory :unconfirmed_user, class: User do
    sequence(:temporary_username) { generate(:username) }
  end
end
