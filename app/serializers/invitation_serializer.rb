class InvitationSerializer
  include JSONAPI::Serializer

  attributes :email, :status, :expires_at, :created_at

  attribute :expired do |invitation|
    invitation.expired?
  end

  belongs_to :household, serializer: HouseholdSerializer
  belongs_to :invited_by, serializer: UserSerializer
end
