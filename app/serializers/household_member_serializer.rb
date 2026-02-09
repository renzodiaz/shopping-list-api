class HouseholdMemberSerializer
  include JSONAPI::Serializer

  attributes :role, :created_at

  belongs_to :user, serializer: UserSerializer
end
