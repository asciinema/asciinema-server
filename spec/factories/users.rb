# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    provider "twitter"
    uid "1234"
    email "foo@bar.com"
    name "foo"
    avatar_url ""
  end
end
