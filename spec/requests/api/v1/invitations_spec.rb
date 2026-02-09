require "rails_helper"

RSpec.describe "Api::V1::Invitations", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }
  let(:household) { create(:household) }
  let(:owner) { create(:user) }
  let!(:owner_membership) { create(:household_member, :owner, user: owner, household: household) }

  describe "GET /api/v1/invitations/:token" do
    let(:invitation) { create(:invitation, household: household, invited_by: owner) }

    context "with valid token" do
      it "returns the invitation" do
        get "/api/v1/invitations/#{invitation.token}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "email")).to eq(invitation.email)
      end

      it "includes household info" do
        get "/api/v1/invitations/#{invitation.token}", headers: headers
        expect(json_response["included"]).to be_present
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get "/api/v1/invitations/invalid-token", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/invitations/#{invitation.token}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/invitations/:token/accept" do
    let(:invitation) { create(:invitation, household: household, invited_by: owner, email: user.email) }

    context "with valid pending invitation" do
      it "creates a household membership" do
        expect {
          post "/api/v1/invitations/#{invitation.token}/accept", headers: headers
        }.to change(HouseholdMember, :count).by(1)
      end

      it "marks the invitation as accepted" do
        post "/api/v1/invitations/#{invitation.token}/accept", headers: headers
        expect(invitation.reload.status).to eq("accepted")
      end

      it "returns the updated invitation" do
        post "/api/v1/invitations/#{invitation.token}/accept", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "status")).to eq("accepted")
      end

      it "adds user as member role" do
        post "/api/v1/invitations/#{invitation.token}/accept", headers: headers
        membership = household.household_members.find_by(user: user)
        expect(membership.role).to eq("member")
      end
    end

    context "when already a member" do
      let(:existing_invitation) { create(:invitation, household: household, invited_by: owner) }

      before { create(:household_member, user: user, household: household) }

      it "returns unprocessable entity" do
        post "/api/v1/invitations/#{existing_invitation.token}/accept", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("already a member")
      end
    end

    context "with expired invitation" do
      let(:expired_invitation) { create(:invitation, :expired, household: household, invited_by: owner) }

      it "returns unprocessable entity" do
        post "/api/v1/invitations/#{expired_invitation.token}/accept", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("expired")
      end
    end

    context "with already accepted invitation" do
      let(:accepted_invitation) { create(:invitation, :accepted, household: household, invited_by: owner) }

      it "returns unprocessable entity" do
        post "/api/v1/invitations/#{accepted_invitation.token}/accept", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("already been accepted")
      end
    end

    context "with declined invitation" do
      let(:declined_invitation) { create(:invitation, :declined, household: household, invited_by: owner) }

      it "returns unprocessable entity" do
        post "/api/v1/invitations/#{declined_invitation.token}/accept", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("already been declined")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/invitations/#{invitation.token}/accept"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/invitations/:token/decline" do
    let(:invitation) { create(:invitation, household: household, invited_by: owner) }

    context "with valid pending invitation" do
      it "marks the invitation as declined" do
        post "/api/v1/invitations/#{invitation.token}/decline", headers: headers
        expect(invitation.reload.status).to eq("declined")
      end

      it "returns the updated invitation" do
        post "/api/v1/invitations/#{invitation.token}/decline", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "status")).to eq("declined")
      end

      it "does not create a membership" do
        expect {
          post "/api/v1/invitations/#{invitation.token}/decline", headers: headers
        }.not_to change(HouseholdMember, :count)
      end
    end

    context "with already accepted invitation" do
      let(:accepted_invitation) { create(:invitation, :accepted, household: household, invited_by: owner) }

      it "returns unprocessable entity" do
        post "/api/v1/invitations/#{accepted_invitation.token}/decline", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/invitations/#{invitation.token}/decline"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
