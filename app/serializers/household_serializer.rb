class HouseholdSerializer
  include JSONAPI::Serializer

  attributes :name, :created_at, :updated_at

  attribute :members_count do |household|
    household.household_members.count
  end

  attribute :role do |household, params|
    if params[:current_user]
      household.household_members.find_by(user: params[:current_user])&.role
    end
  end

  has_one :owner, serializer: UserSerializer
end
