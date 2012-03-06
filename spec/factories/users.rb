# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:uid) { |n| n }

  factory :user do
    provider "twitter"
    uid
    nickname "mrFoo"
    email nil
    name nil
    avatar_url nil
  end
end
