FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 1)}#{n}" }
    description { Faker::Lorem.sentence }
    icon { nil }
  end
end
