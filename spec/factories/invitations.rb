FactoryBot.define do
  factory :invitation do
    household
    email { Faker::Internet.email }
    invited_by { association :user }
    status { :pending }

    trait :accepted do
      status { :accepted }
    end

    trait :declined do
      status { :declined }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
