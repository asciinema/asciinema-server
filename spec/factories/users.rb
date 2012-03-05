# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:uid) { |n| n }
  sequence(:nickname) { |n| "mrFoo#{n}" }

  factory :user do
    provider "twitter"
    uid
    nickname
    email nil
    name nil
    avatar_url nil
  end
end
