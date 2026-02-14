module HouseholdAuthorizable
  extend ActiveSupport::Concern

  private

  def current_membership
    @current_membership ||= @household.household_members.find_by(user: current_user)
  end

  def authorize_member!
    return if current_membership.present?

    render json: {
      errors: [{ status: "403", title: "Forbidden", detail: "You are not a member of this household" }]
    }, status: :forbidden
  end

  def authorize_owner!
    return if current_membership&.owner?

    render json: {
      errors: [{ status: "403", title: "Forbidden", detail: "Only the owner can perform this action" }]
    }, status: :forbidden
  end
end
