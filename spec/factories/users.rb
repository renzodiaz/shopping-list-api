FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    email_confirmed_at { Time.current }

    trait :confirmed do
      email_confirmed_at { Time.current }
    end

    trait :unconfirmed do
      email_confirmed_at { nil }
    end

    trait :with_pending_otp do
      email_confirmed_at { nil }
      after(:create) do |user|
        user.generate_email_confirmation_otp!
      end
    end

    trait :with_access_token do
      after(:create) do |user|
        application = create(:oauth_application)
        create(:access_token, resource_owner_id: user.id, application: application)
      end
    end
  end
end
