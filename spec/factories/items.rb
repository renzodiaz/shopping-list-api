FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "#{Faker::Food.ingredient}#{n}" }
    description { Faker::Lorem.sentence }
    brand { Faker::Company.name }
    icon { nil }
    is_default { false }
    category

    trait :default do
      is_default { true }
    end

    trait :with_unit_type do
      default_unit_type { association :unit_type }
    end
  end
end
