FactoryBot.define do
  factory :household_member do
    user
    household
    role { :member }

    trait :owner do
      role { :owner }
    end
  end
end
