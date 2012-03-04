# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_token do
    association :user
    sequence(:token) { |n| "2b4b4e02-6613-11e1-9be5-#{Kernel.format('%012i', n)}" }
  end
end
