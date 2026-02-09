module Api::V1
  class InvitationsController < BaseController
    before_action :set_invitation

    def show
      serialize(@invitation, serializer: InvitationSerializer, options: { include: %i[household invited_by] })
    end

    def accept
      unless @invitation.acceptable?
        return render json: {
          errors: [ { status: "422", title: "Unprocessable Entity", detail: invitation_error_message } ]
        }, status: :unprocessable_entity
      end

      if current_user_already_member?
        return render json: {
          errors: [ { status: "422", title: "Unprocessable Entity", detail: "You are already a member of this household" } ]
        }, status: :unprocessable_entity
      end

      Invitation.transaction do
        HouseholdMember.create!(user: current_user, household: @invitation.household, role: :member)
        @invitation.accepted!
      end

      serialize(@invitation, serializer: InvitationSerializer, options: { include: %i[household] })
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: format_errors(e.record.errors) }, status: :unprocessable_entity
    end

    def decline
      unless @invitation.pending?
        return render json: {
          errors: [ { status: "422", title: "Unprocessable Entity", detail: "Invitation has already been #{@invitation.status}" } ]
        }, status: :unprocessable_entity
      end

      @invitation.declined!
      serialize(@invitation, serializer: InvitationSerializer)
    end

    private

    def set_invitation
      @invitation = Invitation.find_by!(token: params[:token])
    rescue ActiveRecord::RecordNotFound
      render json: {
        errors: [ { status: "404", title: "Not Found", detail: "Invitation not found" } ]
      }, status: :not_found
    end

    def current_user_already_member?
      @invitation.household.household_members.exists?(user: current_user)
    end

    def invitation_error_message
      if @invitation.expired?
        "This invitation has expired"
      elsif @invitation.accepted?
        "This invitation has already been accepted"
      elsif @invitation.declined?
        "This invitation has already been declined"
      else
        "This invitation cannot be accepted"
      end
    end
  end
end
