FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    jti { SecureRandom.uuid }

    trait :with_access_token do
      after(:create) do |user|
        application = create(:oauth_application)
        create(:access_token, resource_owner_id: user.id, application: application)
      end
    end
  end
end
