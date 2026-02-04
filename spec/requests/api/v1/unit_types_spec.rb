require "rails_helper"

RSpec.describe "Api::V1::UnitTypes", type: :request do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
  let(:headers) { auth_header(access_token.token) }

  describe "GET /api/v1/unit_types" do
    before do
      create_list(:unit_type, 3)
    end

    context "with valid authentication" do
      it "returns a list of unit types" do
        get "/api/v1/unit_types", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response["data"].size).to eq(3)
      end

      it "returns unit types in alphabetical order" do
        UnitType.destroy_all
        create(:unit_type, name: "Zebra", abbreviation: "zb")
        create(:unit_type, name: "Apple", abbreviation: "ap")
        create(:unit_type, name: "Mango", abbreviation: "mg")

        get "/api/v1/unit_types", headers: headers
        names = json_response["data"].map { |u| u.dig("attributes", "name") }
        expect(names).to eq(%w[Apple Mango Zebra])
      end

      it "includes pagination meta" do
        get "/api/v1/unit_types", headers: headers
        expect(json_response["meta"]).to include(
          "current_page",
          "total_pages",
          "total_count"
        )
      end

      it "paginates results" do
        UnitType.destroy_all
        create_list(:unit_type, 30)

        get "/api/v1/unit_types", params: { page: 1, per_page: 10 }, headers: headers
        expect(json_response["data"].size).to eq(10)
        expect(json_response["meta"]["total_count"]).to eq(30)
        expect(json_response["meta"]["total_pages"]).to eq(3)
      end

      it "includes abbreviation in response" do
        UnitType.destroy_all
        create(:unit_type, name: "Kilogram", abbreviation: "kg")

        get "/api/v1/unit_types", headers: headers
        expect(json_response["data"].first.dig("attributes", "abbreviation")).to eq("kg")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/unit_types"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/unit_types/:id" do
    let(:unit_type) { create(:unit_type, name: "Kilogram", abbreviation: "kg") }

    context "with valid authentication" do
      it "returns the unit type" do
        get "/api/v1/unit_types/#{unit_type.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("data", "attributes", "name")).to eq("Kilogram")
        expect(json_response.dig("data", "attributes", "abbreviation")).to eq("kg")
      end

      it "returns not found for non-existent unit type" do
        get "/api/v1/unit_types/999999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/unit_types/#{unit_type.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
