module Api::V1::Households
  class MembersController < Api::V1::BaseController
    include HouseholdAuthorizable

    before_action :set_household
    before_action :authorize_member!
    before_action :authorize_owner!, only: [:destroy]
    before_action :set_member, only: [:destroy]

    def index
      members = @household.household_members.includes(:user)
      serialize(members, serializer: HouseholdMemberSerializer, options: { include: [:user] })
    end

    def destroy
      if @member.owner?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Cannot remove the owner" }]
        }, status: :unprocessable_entity
      end

      user = @member.user
      @member.destroy
      NotificationService.notify_member_left(@household, user)
      head :no_content
    end

    def leave
      membership = current_membership

      if membership.nil?
        return render json: {
          errors: [{ status: "404", title: "Not Found", detail: "You are not a member of this household" }]
        }, status: :not_found
      end

      if membership.owner?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Owner cannot leave the household. Transfer ownership or delete the household instead." }]
        }, status: :unprocessable_entity
      end

      membership.destroy
      NotificationService.notify_member_left(@household, current_user)
      head :no_content
    end

    private

    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_member
      @member = @household.household_members.find(params[:id])
    end
  end
end
