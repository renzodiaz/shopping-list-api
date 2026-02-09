require "rails_helper"

RSpec.describe "Api::V1::Households::Invitations", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }
  let(:household) { create(:household) }
  let!(:owner_membership) { create(:household_member, :owner, user: user, household: household) }

  describe "GET /api/v1/households/:household_id/invitations" do
    let!(:pending_invitation) { create(:invitation, household: household, invited_by: user) }
    let!(:accepted_invitation) { create(:invitation, :accepted, household: household, invited_by: user) }

    context "as owner" do
      it "returns pending invitations" do
        get "/api/v1/households/#{household.id}/invitations", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(1)
      end

      it "does not include accepted/declined invitations" do
        get "/api/v1/households/#{household.id}/invitations", headers: headers
        statuses = json_response["data"].map { |i| i.dig("attributes", "status") }
        expect(statuses).to all(eq("pending"))
      end
    end

    context "as member" do
      let(:member) { create(:user) }
      let!(:member_membership) { create(:household_member, user: member, household: household) }
      let(:member_token) { create(:access_token, resource_owner_id: member.id, application: application) }
      let(:member_headers) { auth_header(member_token.token) }

      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/invitations", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      let(:other_user) { create(:user) }
      let(:other_token) { create(:access_token, resource_owner_id: other_user.id, application: application) }
      let(:other_headers) { auth_header(other_token.token) }

      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/invitations", headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households/#{household.id}/invitations"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/invitations" do
    let(:valid_params) { { invitation: { email: "invitee@example.com" } } }

    context "as owner" do
      it "creates an invitation" do
        expect {
          post "/api/v1/households/#{household.id}/invitations", params: valid_params, headers: headers
        }.to change(Invitation, :count).by(1)
      end

      it "returns created status" do
        post "/api/v1/households/#{household.id}/invitations", params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it "sets the invited_by to current user" do
        post "/api/v1/households/#{household.id}/invitations", params: valid_params, headers: headers
        expect(Invitation.last.invited_by).to eq(user)
      end

      it "returns the invitation with token" do
        post "/api/v1/households/#{household.id}/invitations", params: valid_params, headers: headers
        expect(json_response.dig("data", "attributes", "email")).to eq("invitee@example.com")
      end

      context "with invalid params" do
        it "returns error for invalid email" do
          post "/api/v1/households/#{household.id}/invitations", params: { invitation: { email: "invalid" } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error for existing member" do
          member = create(:user, email: "member@example.com")
          create(:household_member, user: member, household: household)

          post "/api/v1/households/#{household.id}/invitations", params: { invitation: { email: "member@example.com" } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as member" do
      let(:member) { create(:user) }
      let!(:member_membership) { create(:household_member, user: member, household: household) }
      let(:member_token) { create(:access_token, resource_owner_id: member.id, application: application) }
      let(:member_headers) { auth_header(member_token.token) }

      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/invitations", params: valid_params, headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/households/#{household.id}/invitations", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/households/:household_id/invitations/:id" do
    let!(:invitation) { create(:invitation, household: household, invited_by: user) }

    context "as owner" do
      it "deletes the invitation" do
        expect {
          delete "/api/v1/households/#{household.id}/invitations/#{invitation.id}", headers: headers
        }.to change(Invitation, :count).by(-1)
      end

      it "returns no content" do
        delete "/api/v1/households/#{household.id}/invitations/#{invitation.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as member" do
      let(:member) { create(:user) }
      let!(:member_membership) { create(:household_member, user: member, household: household) }
      let(:member_token) { create(:access_token, resource_owner_id: member.id, application: application) }
      let(:member_headers) { auth_header(member_token.token) }

      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}/invitations/#{invitation.id}", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete "/api/v1/households/#{household.id}/invitations/#{invitation.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
