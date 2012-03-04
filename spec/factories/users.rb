# Read about factories at http://github.com/thoughtbot/factory_girl
Factory.sequence(:uid) { |n| n }

FactoryGirl.define do
  factory :user do
    provider "twitter"
    uid { Factory.next(:uid) }
    nickname "mrFoo"
    email nil
    name nil
    avatar_url nil
  end
end
