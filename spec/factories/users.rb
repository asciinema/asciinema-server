# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    provider "twitter"
    sequence(:uid) { |n| "uid-#{n}" }
    nickname "mrFoo"
    email nil
    name nil
    avatar_url nil
  end
end
