require "rails_helper"

RSpec.describe "Api::V1::Households::Members", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }
  let(:household) { create(:household) }

  describe "GET /api/v1/households/:household_id/members" do
    let!(:owner_membership) { create(:household_member, :owner, user: user, household: household) }
    let!(:member_user) { create(:user) }
    let!(:member_membership) { create(:household_member, user: member_user, household: household) }

    context "as a member" do
      it "returns all members" do
        get "/api/v1/households/#{household.id}/members", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(2)
      end

      it "includes user data" do
        get "/api/v1/households/#{household.id}/members", headers: headers
        expect(json_response["included"]).to be_present
        user_types = json_response["included"].map { |i| i["type"] }
        expect(user_types).to all(eq("user"))
      end

      it "includes role information" do
        get "/api/v1/households/#{household.id}/members", headers: headers
        roles = json_response["data"].map { |m| m.dig("attributes", "role") }
        expect(roles).to contain_exactly("owner", "member")
      end
    end

    context "as non-member" do
      let(:other_user) { create(:user) }
      let(:other_token) { create(:access_token, resource_owner_id: other_user.id, application: application) }
      let(:other_headers) { auth_header(other_token.token) }

      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/members", headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households/#{household.id}/members"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/households/:household_id/members/:id" do
    let!(:owner_membership) { create(:household_member, :owner, user: user, household: household) }
    let(:member_user) { create(:user) }
    let!(:member_membership) { create(:household_member, user: member_user, household: household) }

    context "as owner" do
      it "removes the member" do
        expect {
          delete "/api/v1/households/#{household.id}/members/#{member_membership.id}", headers: headers
        }.to change(HouseholdMember, :count).by(-1)
      end

      it "returns no content" do
        delete "/api/v1/households/#{household.id}/members/#{member_membership.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end

      it "cannot remove the owner" do
        delete "/api/v1/households/#{household.id}/members/#{owner_membership.id}", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to eq("Cannot remove the owner")
      end
    end

    context "as member" do
      let(:member_token) { create(:access_token, resource_owner_id: member_user.id, application: application) }
      let(:member_headers) { auth_header(member_token.token) }

      it "returns forbidden" do
        another_member = create(:user)
        another_membership = create(:household_member, user: another_member, household: household)

        delete "/api/v1/households/#{household.id}/members/#{another_membership.id}", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      let(:other_user) { create(:user) }
      let(:other_token) { create(:access_token, resource_owner_id: other_user.id, application: application) }
      let(:other_headers) { auth_header(other_token.token) }

      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}/members/#{member_membership.id}", headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete "/api/v1/households/#{household.id}/members/#{member_membership.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/leave" do
    let(:owner) { create(:user) }
    let!(:owner_membership) { create(:household_member, :owner, user: owner, household: household) }
    let!(:member_membership) { create(:household_member, user: user, household: household) }

    context "as member" do
      it "removes the membership" do
        expect {
          post "/api/v1/households/#{household.id}/leave", headers: headers
        }.to change(HouseholdMember, :count).by(-1)
      end

      it "returns no content" do
        post "/api/v1/households/#{household.id}/leave", headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as owner" do
      let(:owner_token) { create(:access_token, resource_owner_id: owner.id, application: application) }
      let(:owner_headers) { auth_header(owner_token.token) }

      it "returns unprocessable entity" do
        post "/api/v1/households/#{household.id}/leave", headers: owner_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "includes error message about ownership" do
        post "/api/v1/households/#{household.id}/leave", headers: owner_headers
        expect(json_response["errors"].first["detail"]).to include("Owner cannot leave")
      end
    end

    context "as non-member" do
      let(:other_user) { create(:user) }
      let(:other_token) { create(:access_token, resource_owner_id: other_user.id, application: application) }
      let(:other_headers) { auth_header(other_token.token) }

      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/leave", headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/households/#{household.id}/leave"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
