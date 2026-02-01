FactoryBot.define do
  factory :jwt_blocklist do
    jti { "MyString" }
    exp { "2026-01-31 17:31:47" }
  end
end
