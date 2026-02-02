FactoryBot.define do
  factory :oauth_application, class: "Doorkeeper::Application" do
    name { Faker::App.name }
    redirect_uri { "urn:ietf:wg:oauth:2.0:oob" }
    scopes { "" }
    confidential { true }
  end

  factory :access_token, class: "Doorkeeper::AccessToken" do
    application { association :oauth_application }
    resource_owner_id { create(:user).id }
    expires_in { 2.hours }
    scopes { "" }

    trait :expired do
      created_at { 3.hours.ago }
      expires_in { 2.hours }
    end

    trait :revoked do
      revoked_at { 1.hour.ago }
    end
  end

  factory :access_grant, class: "Doorkeeper::AccessGrant" do
    application { association :oauth_application }
    resource_owner_id { create(:user).id }
    expires_in { 10.minutes }
    redirect_uri { "urn:ietf:wg:oauth:2.0:oob" }
    scopes { "" }
  end
end
