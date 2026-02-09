module Api::V1::Households
  class MembersController < Api::V1::BaseController
    before_action :set_household
    before_action :authorize_member!
    before_action :authorize_owner!, only: [ :destroy ]
    before_action :set_member, only: [ :destroy ]

    def index
      members = @household.household_members.includes(:user)
      serialize(members, serializer: HouseholdMemberSerializer, options: { include: [ :user ] })
    end

    def destroy
      if @member.owner?
        return render json: {
          errors: [ { status: "422", title: "Unprocessable Entity", detail: "Cannot remove the owner" } ]
        }, status: :unprocessable_entity
      end

      @member.destroy
      head :no_content
    end

    def leave
      membership = @household.household_members.find_by(user: current_user)

      if membership.nil?
        return render json: {
          errors: [ { status: "404", title: "Not Found", detail: "You are not a member of this household" } ]
        }, status: :not_found
      end

      if membership.owner?
        return render json: {
          errors: [ { status: "422", title: "Unprocessable Entity", detail: "Owner cannot leave the household. Transfer ownership or delete the household instead." } ]
        }, status: :unprocessable_entity
      end

      membership.destroy
      head :no_content
    end

    private

    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_member
      @member = @household.household_members.find(params[:id])
    end

    def authorize_member!
      return if @household.household_members.exists?(user: current_user)

      render json: {
        errors: [ { status: "403", title: "Forbidden", detail: "You are not a member of this household" } ]
      }, status: :forbidden
    end

    def authorize_owner!
      return if @household.household_members.owners.exists?(user: current_user)

      render json: {
        errors: [ { status: "403", title: "Forbidden", detail: "Only the owner can perform this action" } ]
      }, status: :forbidden
    end
  end
end
