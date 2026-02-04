require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }

  describe "GET /api/v1/categories" do
    before do
      create_list(:category, 3)
    end

    context "with valid authentication" do
      it "returns a list of categories" do
        get "/api/v1/categories", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(3)
      end

      it "returns categories in alphabetical order" do
        Category.destroy_all
        create(:category, name: "Zebra")
        create(:category, name: "Apple")
        create(:category, name: "Mango")

        get "/api/v1/categories", headers: headers
        names = json_response["data"].map { |c| c.dig("attributes", "name") }
        expect(names).to eq(%w[Apple Mango Zebra])
      end

      it "includes pagination meta" do
        get "/api/v1/categories", headers: headers
        expect(json_response["meta"]).to include(
          "current_page",
          "total_pages",
          "total_count"
        )
      end

      it "paginates results" do
        Category.destroy_all
        create_list(:category, 30)

        get "/api/v1/categories", params: { page: 1, per_page: 10 }, headers: headers
        expect(json_response["data"].size).to eq(10)
        expect(json_response["meta"]["total_count"]).to eq(30)
        expect(json_response["meta"]["total_pages"]).to eq(3)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/categories"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/categories/:id" do
    let(:category) { create(:category, name: "Dairy", description: "Milk products") }

    context "with valid authentication" do
      it "returns the category" do
        get "/api/v1/categories/#{category.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq("Dairy")
        expect(json_response.dig("data", "attributes", "description")).to eq("Milk products")
      end

      it "returns not found for non-existent category" do
        get "/api/v1/categories/999999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/categories/#{category.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
