FactoryBot.define do
  factory :shopping_list_item do
    shopping_list
    item { nil }
    sequence(:custom_name) { |n| "Custom Item #{n}" }
    quantity { 1 }
    unit_type { nil }
    status { :pending }
    added_by { association :user }
    checked_at { nil }
    position { nil }

    trait :with_item do
      item
      custom_name { nil }
    end

    trait :checked do
      status { :checked }
      checked_at { Time.current }
    end

    trait :not_in_stock do
      status { :not_in_stock }
      checked_at { Time.current }
    end
  end
end
