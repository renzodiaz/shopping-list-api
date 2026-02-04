FactoryBot.define do
  factory :unit_type do
    sequence(:name) { |n| "Unit#{n}" }
    sequence(:abbreviation) { |n| "u#{n}" }
  end
end
