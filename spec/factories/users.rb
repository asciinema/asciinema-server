# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    provider "twitter"
    uid "1234"
    email nil
    name "foo"
    avatar_url nil
  end
end
