FactoryBot.define do
  factory :inventory_item do
    household
    item { nil }
    sequence(:custom_name) { |n| "Custom Inventory Item #{n}" }
    quantity { 10 }
    unit_type { nil }
    low_stock_threshold { 2 }
    created_by { association :user }

    trait :with_item do
      item
      custom_name { nil }
    end

    trait :low_stock do
      quantity { 2 }
      low_stock_threshold { 5 }
    end

    trait :out_of_stock do
      quantity { 0 }
    end
  end
end
