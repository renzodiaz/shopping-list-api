class UserSerializer
  include JSONAPI::Serializer
  attributes :email, :created_at

  attribute :email_confirmed do |user|
    user.email_confirmed?
  end
end
