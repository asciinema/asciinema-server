FactoryGirl.define do
  factory :comment do
    body "My fancy comment"
    association :user
    association :asciicast
  end
end
