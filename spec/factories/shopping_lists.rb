FactoryBot.define do
  factory :shopping_list do
    household
    sequence(:name) { |n| "Shopping List #{n}" }
    status { :active }
    created_by { association :user }
    completed_at { nil }

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end

    trait :archived do
      status { :archived }
    end
  end
end
