FactoryBot.define do
  factory :device_token do
    user
    sequence(:token) { |n| "device_token_#{n}_#{SecureRandom.hex(32)}" }
    platform { "ios" }
    device_name { "iPhone 15 Pro" }

    trait :ios do
      platform { "ios" }
      device_name { "iPhone 15 Pro" }
    end

    trait :android do
      platform { "android" }
      device_name { "Pixel 8" }
    end

    trait :web do
      platform { "web" }
      device_name { "Chrome Browser" }
    end
  end
end
