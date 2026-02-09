require "rails_helper"

RSpec.describe "Api::V1::Households", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }

  describe "GET /api/v1/households" do
    context "with valid authentication" do
      let!(:owned_household) do
        household = create(:household, name: "My Home")
        create(:household_member, :owner, user: user, household: household)
        household
      end

      let!(:member_household) do
        household = create(:household, name: "Friend's Home")
        create(:household_member, :owner, household: household)
        create(:household_member, user: user, household: household)
        household
      end

      it "returns user's households" do
        get "/api/v1/households", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(2)
      end

      it "includes role for each household" do
        get "/api/v1/households", headers: headers
        roles = json_response["data"].map { |h| h.dig("attributes", "role") }
        expect(roles).to contain_exactly("owner", "member")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/households/:id" do
    let(:household) { create(:household) }

    context "as a member" do
      before { create(:household_member, user: user, household: household) }

      it "returns the household" do
        get "/api/v1/households/#{household.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq(household.name)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/households/#{household.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households/#{household.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/households" do
    let(:valid_params) { { household: { name: "New Home" } } }

    context "with valid authentication" do
      it "creates a household" do
        expect {
          post "/api/v1/households", params: valid_params, headers: headers
        }.to change(Household, :count).by(1)
      end

      it "returns created status" do
        post "/api/v1/households", params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it "makes the user the owner" do
        post "/api/v1/households", params: valid_params, headers: headers
        household = Household.last
        expect(household.owner).to eq(user)
      end

      it "returns the household with owner role" do
        post "/api/v1/households", params: valid_params, headers: headers
        expect(json_response.dig("data", "attributes", "role")).to eq("owner")
      end

      context "when user already owns a household" do
        before do
          existing = create(:household)
          create(:household_member, :owner, user: user, household: existing)
        end

        it "returns unprocessable entity" do
          post "/api/v1/households", params: valid_params, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "does not create a household" do
          expect {
            post "/api/v1/households", params: valid_params, headers: headers
          }.not_to change(Household, :count)
        end
      end

      context "with invalid params" do
        it "returns unprocessable entity for missing name" do
          post "/api/v1/households", params: { household: { name: "" } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/households", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/households/:id" do
    let(:household) { create(:household, name: "Old Name") }

    context "as owner" do
      before { create(:household_member, :owner, user: user, household: household) }

      it "updates the household" do
        patch "/api/v1/households/#{household.id}", params: { household: { name: "New Name" } }, headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq("New Name")
      end

      it "updates the database" do
        patch "/api/v1/households/#{household.id}", params: { household: { name: "New Name" } }, headers: headers
        expect(household.reload.name).to eq("New Name")
      end
    end

    context "as member" do
      before { create(:household_member, user: user, household: household) }

      it "returns forbidden" do
        patch "/api/v1/households/#{household.id}", params: { household: { name: "New Name" } }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        patch "/api/v1/households/#{household.id}", params: { household: { name: "New Name" } }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        patch "/api/v1/households/#{household.id}", params: { household: { name: "New Name" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/households/:id" do
    let!(:household) { create(:household) }

    context "as owner" do
      before { create(:household_member, :owner, user: user, household: household) }

      it "deletes the household" do
        expect {
          delete "/api/v1/households/#{household.id}", headers: headers
        }.to change(Household, :count).by(-1)
      end

      it "returns no content" do
        delete "/api/v1/households/#{household.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as member" do
      before { create(:household_member, user: user, household: household) }

      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "does not delete the household" do
        expect {
          delete "/api/v1/households/#{household.id}", headers: headers
        }.not_to change(Household, :count)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete "/api/v1/households/#{household.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
