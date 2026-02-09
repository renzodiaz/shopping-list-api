module Api::V1::Households
  class InvitationsController < Api::V1::BaseController
    before_action :set_household
    before_action :authorize_owner!
    before_action :set_invitation, only: [ :destroy ]

    def index
      invitations = @household.invitations.pending.includes(:invited_by)
      serialize(invitations, serializer: InvitationSerializer, options: { include: [ :invited_by ] })
    end

    def create
      invitation = @household.invitations.new(invitation_params)
      invitation.invited_by = current_user

      if invitation.save
        serialize(invitation, serializer: InvitationSerializer, status: :created, options: { include: %i[household invited_by] })
      else
        unprocessable_entity!(invitation)
      end
    end

    def destroy
      @invitation.destroy
      head :no_content
    end

    private

    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_invitation
      @invitation = @household.invitations.find(params[:id])
    end

    def invitation_params
      params.require(:invitation).permit(:email)
    end

    def authorize_owner!
      return if @household.household_members.owners.exists?(user: current_user)

      render json: {
        errors: [ { status: "403", title: "Forbidden", detail: "Only the owner can manage invitations" } ]
      }, status: :forbidden
    end
  end
end
