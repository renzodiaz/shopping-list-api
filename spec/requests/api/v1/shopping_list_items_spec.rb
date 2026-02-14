require "rails_helper"

RSpec.describe "Api::V1::ShoppingListItems", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:household) { create(:household) }
  let!(:owner_membership) { create(:household_member, :owner, user: owner, household: household) }
  let!(:member_membership) { create(:household_member, user: member, household: household) }
  let(:shopping_list) { create(:shopping_list, household: household, created_by: owner) }
  let(:application) { create(:oauth_application) }
  let(:owner_token) { create(:access_token, resource_owner_id: owner.id, application: application) }
  let(:member_token) { create(:access_token, resource_owner_id: member.id, application: application) }
  let(:non_member_token) { create(:access_token, resource_owner_id: non_member.id, application: application) }
  let(:owner_headers) { auth_header(owner_token.token) }
  let(:member_headers) { auth_header(member_token.token) }
  let(:non_member_headers) { auth_header(non_member_token.token) }

  describe "GET /api/v1/shopping_lists/:shopping_list_id/items" do
    let!(:pending_item) { create(:shopping_list_item, shopping_list: shopping_list, status: :pending) }
    let!(:checked_item) { create(:shopping_list_item, :checked, shopping_list: shopping_list) }

    context "as member" do
      it "returns all items ordered (pending first)" do
        get "/api/v1/shopping_lists/#{shopping_list.id}/items", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].length).to eq(2)
        expect(json_response["data"].first["id"]).to eq(pending_item.id.to_s)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        get "/api/v1/shopping_lists/#{shopping_list.id}/items", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/shopping_lists/#{shopping_list.id}/items"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/shopping_lists/:shopping_list_id/items" do
    context "with custom name" do
      let(:valid_params) { { item: { custom_name: "Organic Milk", quantity: 2 } } }

      context "as member" do
        it "creates a shopping list item" do
          expect {
            post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: member_headers
          }.to change(ShoppingListItem, :count).by(1)
          expect(response).to have_http_status(:created)
        end

        it "sets the added_by to current user" do
          post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: member_headers
          expect(ShoppingListItem.last.added_by).to eq(member)
        end
      end

      context "as owner" do
        it "creates a shopping list item" do
          expect {
            post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: owner_headers
          }.to change(ShoppingListItem, :count).by(1)
        end
      end

      context "as non-member" do
        it "returns forbidden" do
          post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: non_member_headers
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "with catalog item" do
      let(:catalog_item) { create(:item) }
      let(:valid_params) { { item: { item_id: catalog_item.id, quantity: 1 } } }

      it "creates a shopping list item with catalog reference" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: member_headers
        expect(response).to have_http_status(:created)
        expect(ShoppingListItem.last.item).to eq(catalog_item)
      end
    end

    context "with unit type" do
      let(:unit_type) { create(:unit_type) }
      let(:valid_params) { { item: { custom_name: "Sugar", quantity: 500, unit_type_id: unit_type.id } } }

      it "creates an item with unit type" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items", params: valid_params, headers: member_headers
        expect(response).to have_http_status(:created)
        expect(ShoppingListItem.last.unit_type).to eq(unit_type)
      end
    end

    context "with invalid data" do
      it "returns validation errors when no name or item" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items",
             params: { item: { quantity: 1 } },
             headers: member_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors for invalid quantity" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items",
             params: { item: { custom_name: "Milk", quantity: -1 } },
             headers: member_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /api/v1/shopping_lists/:shopping_list_id/items/:id" do
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list, custom_name: "Milk", quantity: 1) }

    context "as member" do
      it "updates the item" do
        put "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}",
            params: { item: { quantity: 3 } },
            headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(list_item.reload.quantity).to eq(3)
      end
    end

    context "as owner" do
      it "updates the item" do
        put "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}",
            params: { item: { custom_name: "Whole Milk" } },
            headers: owner_headers
        expect(response).to have_http_status(:ok)
        expect(list_item.reload.custom_name).to eq("Whole Milk")
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        put "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}",
            params: { item: { quantity: 3 } },
            headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v1/shopping_lists/:shopping_list_id/items/:id" do
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list) }

    context "as member" do
      it "deletes the item" do
        expect {
          delete "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}", headers: member_headers
        }.to change(ShoppingListItem, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as owner" do
      it "deletes the item" do
        expect {
          delete "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}", headers: owner_headers
        }.to change(ShoppingListItem, :count).by(-1)
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        delete "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/shopping_lists/:shopping_list_id/items/:id/check" do
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list, status: :pending) }

    context "as member" do
      it "marks the item as checked" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/check", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(list_item.reload.status).to eq("checked")
      end

      it "sets checked_at timestamp" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/check", headers: member_headers
        expect(list_item.reload.checked_at).to be_present
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/check", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/shopping_lists/:shopping_list_id/items/:id/uncheck" do
    let!(:list_item) { create(:shopping_list_item, :checked, shopping_list: shopping_list) }

    context "as member" do
      it "marks the item as pending" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/uncheck", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(list_item.reload.status).to eq("pending")
      end

      it "clears checked_at timestamp" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/uncheck", headers: member_headers
        expect(list_item.reload.checked_at).to be_nil
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/uncheck", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/shopping_lists/:shopping_list_id/items/:id/not_in_stock" do
    let!(:list_item) { create(:shopping_list_item, shopping_list: shopping_list, status: :pending) }

    context "as member" do
      it "marks the item as not in stock" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/not_in_stock", headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(list_item.reload.status).to eq("not_in_stock")
      end

      it "sets checked_at timestamp" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/not_in_stock", headers: member_headers
        expect(list_item.reload.checked_at).to be_present
      end
    end

    context "as non-member" do
      it "returns forbidden" do
        post "/api/v1/shopping_lists/#{shopping_list.id}/items/#{list_item.id}/not_in_stock", headers: non_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
