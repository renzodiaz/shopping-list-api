require "rails_helper"

RSpec.describe "Api::V1::Households::InventoryItems", type: :request do
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

  describe "GET /api/v1/households/:household_id/inventory" do
    let!(:inventory_item) { create(:inventory_item, household: household, created_by: owner) }

    context "as owner" do
      it "returns all inventory items" do
        get "/api/v1/households/#{household.id}/inventory", headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].length).to eq(1)
      end

      it "includes related item and unit_type" do
        get "/api/v1/households/#{household.id}/inventory", headers: owner_headers
        expect(json_response["data"].first["relationships"]).to include("item", "unit_type", "created_by")
      end
    end

    context "as member" do
      it "returns all inventory items" do
        get "/api/v1/households/#{household.id}/inventory", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].length).to eq(1)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/inventory", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/households/#{household.id}/inventory"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/households/:household_id/inventory/:id" do
    let!(:inventory_item) { create(:inventory_item, household: household, created_by: owner) }

    context "as member" do
      it "returns the inventory item" do
        get "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "custom_name")).to eq(inventory_item.custom_name)
      end

      it "includes computed attributes" do
        get "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: member_headers
        attributes = json_response.dig("data", "attributes")
        expect(attributes).to include("display_name", "low_stock", "out_of_stock")
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/inventory" do
    let(:item) { create(:item) }
    let(:unit_type) { create(:unit_type) }
    let(:valid_params) do
      {
        inventory_item: {
          item_id: item.id,
          quantity: 10,
          unit_type_id: unit_type.id,
          low_stock_threshold: 2
        }
      }
    end
    let(:custom_name_params) do
      {
        inventory_item: {
          custom_name: "Custom Item",
          quantity: 5,
          low_stock_threshold: 1
        }
      }
    end

    context "as owner" do
      it "creates an inventory item with catalog item" do
        expect {
          post "/api/v1/households/#{household.id}/inventory", params: valid_params, headers: owner_headers
        }.to change(InventoryItem, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "creates an inventory item with custom name" do
        expect {
          post "/api/v1/households/#{household.id}/inventory", params: custom_name_params, headers: owner_headers
        }.to change(InventoryItem, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response.dig("data", "attributes", "custom_name")).to eq("Custom Item")
      end

      it "sets the created_by to current user" do
        post "/api/v1/households/#{household.id}/inventory", params: valid_params, headers: owner_headers
        expect(InventoryItem.last.created_by).to eq(owner)
      end

      it "returns validation errors for missing item and custom_name" do
        post "/api/v1/households/#{household.id}/inventory",
             params: { inventory_item: { quantity: 10, low_stock_threshold: 2 } },
             headers: owner_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors for duplicate item in household" do
        create(:inventory_item, :with_item, household: household, item: item, created_by: owner)
        post "/api/v1/households/#{household.id}/inventory", params: valid_params, headers: owner_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/inventory", params: valid_params, headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/inventory", params: valid_params, headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT /api/v1/households/:household_id/inventory/:id" do
    let!(:inventory_item) { create(:inventory_item, household: household, created_by: owner, quantity: 10, low_stock_threshold: 2) }

    context "as owner" do
      it "updates the inventory item" do
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { quantity: 20, low_stock_threshold: 5 } },
            headers: owner_headers
        expect(response).to have_http_status(:ok)
        inventory_item.reload
        expect(inventory_item.quantity).to eq(20)
        expect(inventory_item.low_stock_threshold).to eq(5)
      end

      it "updates custom_name" do
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { custom_name: "Updated Name" } },
            headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.custom_name).to eq("Updated Name")
      end
    end

    context "as member" do
      it "can update quantity only" do
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { quantity: 15 } },
            headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.quantity).to eq(15)
      end

      it "cannot update low_stock_threshold" do
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { quantity: 15, low_stock_threshold: 10 } },
            headers: member_headers
        expect(response).to have_http_status(:ok)
        inventory_item.reload
        expect(inventory_item.quantity).to eq(15)
        expect(inventory_item.low_stock_threshold).to eq(2) # unchanged
      end

      it "cannot update custom_name" do
        original_name = inventory_item.custom_name
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { custom_name: "Changed Name" } },
            headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.custom_name).to eq(original_name) # unchanged
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        put "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}",
            params: { inventory_item: { quantity: 20 } },
            headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v1/households/:household_id/inventory/:id" do
    let!(:inventory_item) { create(:inventory_item, household: household, created_by: owner) }

    context "as owner" do
      it "deletes the inventory item" do
        expect {
          delete "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: owner_headers
        }.to change(InventoryItem, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as member" do
      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        delete "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/households/:household_id/inventory/:id/adjust" do
    let!(:inventory_item) { create(:inventory_item, household: household, created_by: owner, quantity: 10) }

    context "as owner" do
      it "increases quantity with positive amount" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: 5 },
             headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.quantity).to eq(15)
      end

      it "decreases quantity with negative amount" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: -3 },
             headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.quantity).to eq(7)
      end

      it "does not go below zero" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: -20 },
             headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.quantity).to eq(0)
      end

      it "returns error for zero amount" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: 0 },
             headers: owner_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to eq("Amount cannot be zero")
      end
    end

    context "as member" do
      it "can adjust quantity" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: 5 },
             headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(inventory_item.reload.quantity).to eq(15)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: 5 },
             headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/households/#{household.id}/inventory/#{inventory_item.id}/adjust",
             params: { amount: 5 }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
