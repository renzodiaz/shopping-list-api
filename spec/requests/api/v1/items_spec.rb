require "rails_helper"

RSpec.describe "Api::V1::Items", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }
  let(:category) { create(:category) }
  let(:unit_type) { create(:unit_type) }

  describe "GET /api/v1/items" do
    before do
      create_list(:item, 3, category: category)
    end

    context "with valid authentication" do
      it "returns a list of items" do
        get "/api/v1/items", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(3)
      end

      it "returns items in alphabetical order" do
        Item.destroy_all
        create(:item, name: "Zebra", category: category)
        create(:item, name: "Apple", category: category)
        create(:item, name: "Mango", category: category)

        get "/api/v1/items", headers: headers
        names = json_response["data"].map { |i| i.dig("attributes", "name") }
        expect(names).to eq(%w[Apple Mango Zebra])
      end

      it "includes pagination meta" do
        get "/api/v1/items", headers: headers
        expect(json_response["meta"]).to include(
          "current_page",
          "total_pages",
          "total_count"
        )
      end

      it "paginates results" do
        Item.destroy_all
        create_list(:item, 30, category: category)

        get "/api/v1/items", params: { page: 1, per_page: 10 }, headers: headers
        expect(json_response["data"].size).to eq(10)
        expect(json_response["meta"]["total_count"]).to eq(30)
        expect(json_response["meta"]["total_pages"]).to eq(3)
      end

      it "includes category relationship" do
        get "/api/v1/items", headers: headers
        expect(json_response["included"]).to be_present
        category_data = json_response["included"].find { |i| i["type"] == "category" }
        expect(category_data).to be_present
      end

      describe "filtering" do
        let(:other_category) { create(:category) }

        before do
          Item.destroy_all
          create(:item, name: "Milk", category: category)
          create(:item, name: "Cheese", category: category)
          create(:item, name: "Bread", category: other_category)
        end

        it "filters by category_id" do
          get "/api/v1/items", params: { category_id: category.id }, headers: headers
          expect(json_response["data"].size).to eq(2)
          names = json_response["data"].map { |i| i.dig("attributes", "name") }
          expect(names).to contain_exactly("Milk", "Cheese")
        end

        it "searches by name" do
          create(:item, name: "Almond Milk", category: category)

          get "/api/v1/items", params: { search: "milk" }, headers: headers
          expect(json_response["data"].size).to eq(2)
          names = json_response["data"].map { |i| i.dig("attributes", "name") }
          expect(names).to contain_exactly("Milk", "Almond Milk")
        end

        it "combines search and filter" do
          create(:item, name: "Milk Bread", category: other_category)

          get "/api/v1/items", params: { search: "milk", category_id: category.id }, headers: headers
          expect(json_response["data"].size).to eq(1)
          expect(json_response["data"].first.dig("attributes", "name")).to eq("Milk")
        end
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/items"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/items/:id" do
    let(:item) { create(:item, :with_unit_type, category: category, name: "Milk", description: "Fresh milk") }

    context "with valid authentication" do
      it "returns the item" do
        get "/api/v1/items/#{item.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq("Milk")
        expect(json_response.dig("data", "attributes", "description")).to eq("Fresh milk")
      end

      it "includes category and unit type" do
        get "/api/v1/items/#{item.id}", headers: headers
        expect(json_response["included"]).to be_present
      end

      it "returns not found for non-existent item" do
        get "/api/v1/items/999999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/items/#{item.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/items" do
    let(:valid_params) do
      {
        item: {
          name: "Custom Item",
          description: "My custom item",
          brand: "MyBrand",
          category_id: category.id,
          default_unit_type_id: unit_type.id
        }
      }
    end

    context "with valid authentication" do
      it "creates a new item" do
        expect {
          post "/api/v1/items", params: valid_params, headers: headers
        }.to change(Item, :count).by(1)
      end

      it "returns created status" do
        post "/api/v1/items", params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it "returns the created item" do
        post "/api/v1/items", params: valid_params, headers: headers
        expect(json_response.dig("data", "attributes", "name")).to eq("Custom Item")
        expect(json_response.dig("data", "attributes", "brand")).to eq("MyBrand")
      end

      it "sets is_default to false" do
        post "/api/v1/items", params: valid_params, headers: headers
        expect(json_response.dig("data", "attributes", "is_default")).to be false
      end

      context "with invalid params" do
        it "returns unprocessable entity when name is missing" do
          post "/api/v1/items", params: { item: { category_id: category.id } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns unprocessable entity when category is missing" do
          post "/api/v1/items", params: { item: { name: "Test" } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns unprocessable entity for duplicate name in same category" do
          create(:item, name: "Duplicate", category: category)
          post "/api/v1/items", params: { item: { name: "Duplicate", category_id: category.id } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "allows same name in different category" do
          other_category = create(:category)
          create(:item, name: "Same Name", category: category)

          post "/api/v1/items", params: { item: { name: "Same Name", category_id: other_category.id } }, headers: headers
          expect(response).to have_http_status(:created)
        end
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/items", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/items/:id" do
    let(:custom_item) { create(:item, category: category, name: "Original Name") }

    context "with valid authentication" do
      it "updates the item" do
        patch "/api/v1/items/#{custom_item.id}", params: { item: { name: "Updated Name" } }, headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq("Updated Name")
      end

      it "updates the item in database" do
        patch "/api/v1/items/#{custom_item.id}", params: { item: { name: "Updated Name" } }, headers: headers
        expect(custom_item.reload.name).to eq("Updated Name")
      end

      context "with default item" do
        let(:default_item) { create(:item, :default, category: category) }

        it "returns forbidden" do
          patch "/api/v1/items/#{default_item.id}", params: { item: { name: "New Name" } }, headers: headers
          expect(response).to have_http_status(:forbidden)
        end

        it "does not update the item" do
          original_name = default_item.name
          patch "/api/v1/items/#{default_item.id}", params: { item: { name: "New Name" } }, headers: headers
          expect(default_item.reload.name).to eq(original_name)
        end
      end

      context "with invalid params" do
        it "returns unprocessable entity for blank name" do
          patch "/api/v1/items/#{custom_item.id}", params: { item: { name: "" } }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        patch "/api/v1/items/#{custom_item.id}", params: { item: { name: "New Name" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/items/:id" do
    context "with valid authentication" do
      let!(:custom_item) { create(:item, category: category) }

      it "deletes the item" do
        expect {
          delete "/api/v1/items/#{custom_item.id}", headers: headers
        }.to change(Item, :count).by(-1)
      end

      it "returns no content" do
        delete "/api/v1/items/#{custom_item.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end

      context "with default item" do
        let!(:default_item) { create(:item, :default, category: category) }

        it "returns forbidden" do
          delete "/api/v1/items/#{default_item.id}", headers: headers
          expect(response).to have_http_status(:forbidden)
        end

        it "does not delete the item" do
          expect {
            delete "/api/v1/items/#{default_item.id}", headers: headers
          }.not_to change(Item, :count)
        end
      end

      it "returns not found for non-existent item" do
        delete "/api/v1/items/999999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      let!(:custom_item) { create(:item, category: category) }

      it "returns unauthorized" do
        delete "/api/v1/items/#{custom_item.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
