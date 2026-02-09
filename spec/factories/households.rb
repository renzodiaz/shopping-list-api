FactoryBot.define do
  factory :household do
    sequence(:name) { |n| "#{Faker::Address.community}#{n}" }
  end
end
