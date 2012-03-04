# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_token do
    association :user
    token "some-token"
  end
end
