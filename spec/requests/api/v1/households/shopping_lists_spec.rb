require "rails_helper"

RSpec.describe "Api::V1::Households::ShoppingLists", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:household) { create(:household) }
  let!(:owner_membership) { create(:household_member, :owner, user: owner, household: household) }
  let!(:member_membership) { create(:household_member, user: member, household: household) }
  let(:application) { create(:oauth_application) }
  let(:owner_token) { create(:access_token, resource_owner_id: owner.id, application: application) }
  let(:member_token) { create(:access_token, resource_owner_id: member.id, application: application) }
  let(:non_member_token) { create(:access_token, resource_owner_id: non_member.id, application: application) }
  let(:owner_headers) { auth_header(owner_token.token) }
  let(:member_headers) { auth_header(member_token.token) }
  let(:non_member_headers) { auth_header(non_member_token.token) }

  describe "GET /api/v1/households/:household_id/shopping_lists" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner) }

    context "as owner" do
      it "returns all shopping lists" do
        get "/api/v1/households/#{household.id}/shopping_lists", headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].length).to eq(1)
      end
    end

    context "as member" do
      it "returns all shopping lists" do
        get "/api/v1/households/#{household.id}/shopping_lists", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].length).to eq(1)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/shopping_lists", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households/#{household.id}/shopping_lists"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/households/:household_id/shopping_lists/:id" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner) }
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list) }

    context "as member" do
      it "returns the shopping list with items" do
        get "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq(shopping_list.name)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/shopping_lists" do
    let(:valid_params) { { shopping_list: { name: "Weekly Groceries" } } }

    context "as owner" do
      it "creates a shopping list" do
        expect {
          post "/api/v1/households/#{household.id}/shopping_lists", params: valid_params, headers: owner_headers
        }.to change(ShoppingList, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "sets the created_by to current user" do
        post "/api/v1/households/#{household.id}/shopping_lists", params: valid_params, headers: owner_headers
        expect(ShoppingList.last.created_by).to eq(owner)
      end

      it "returns validation errors for invalid data" do
        post "/api/v1/households/#{household.id}/shopping_lists", params: { shopping_list: { name: "" } }, headers: owner_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/shopping_lists", params: valid_params, headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/shopping_lists", params: valid_params, headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT /api/v1/households/:household_id/shopping_lists/:id" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner) }

    context "as owner" do
      it "updates the shopping list" do
        put "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}",
            params: { shopping_list: { name: "Updated Name" } },
            headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(shopping_list.reload.name).to eq("Updated Name")
      end
    end

    context "as member" do
      it "returns forbidden" do
        put "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}",
            params: { shopping_list: { name: "Updated Name" } },
            headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v1/households/:household_id/shopping_lists/:id" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner) }

    context "as owner" do
      it "deletes the shopping list" do
        expect {
          delete "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}", headers: owner_headers
        }.to change(ShoppingList, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as member" do
      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/shopping_lists/:id/complete" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner, status: :active) }

    context "as owner" do
      it "marks the list as completed" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/complete", headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(shopping_list.reload.status).to eq("completed")
      end

      it "sets completed_at timestamp" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/complete", headers: owner_headers
        expect(shopping_list.reload.completed_at).to be_present
      end

      context "when already completed" do
        before { shopping_list.update!(status: :completed) }

        it "returns unprocessable entity" do
          post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/complete", headers: owner_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/complete", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/shopping_lists/:id/duplicate" do
    let!(:shopping_list) { create(:shopping_list, household: household, created_by: owner, name: "Original List") }
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list, custom_name: "Milk") }

    context "as owner" do
      it "creates a duplicate list" do
        expect {
          post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/duplicate", headers: owner_headers
        }.to change(ShoppingList, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "duplicates with default name" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/duplicate", headers: owner_headers
        expect(json_response.dig("data", "attributes", "name")).to eq("Original List (Copy)")
      end

      it "duplicates with custom name" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/duplicate",
             params: { name: "New List" },
             headers: owner_headers
        expect(json_response.dig("data", "attributes", "name")).to eq("New List")
      end

      it "duplicates all items" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/duplicate", headers: owner_headers
        new_list = ShoppingList.find(json_response.dig("data", "id"))
        expect(new_list.shopping_list_items.count).to eq(1)
      end
    end

    context "as member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/shopping_lists/#{shopping_list.id}/duplicate", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
