require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_attributes) do
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/register", params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it "returns a created status" do
        post "/api/v1/auth/register", params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "returns the user data" do
        post "/api/v1/auth/register", params: valid_attributes
        expect(json_response["data"]).to have_key("id")
      end

      it "returns user attributes" do
        post "/api/v1/auth/register", params: valid_attributes
        attributes = json_response.dig("data", "attributes")
        expect(attributes["email"]).to eq("newuser@example.com")
      end

      it "generates a jti for the user" do
        post "/api/v1/auth/register", params: valid_attributes
        user = User.last
        expect(user.jti).to be_present
      end

      it "does not return the password" do
        post "/api/v1/auth/register", params: valid_attributes
        attributes = json_response.dig("data", "attributes")
        expect(attributes).not_to have_key("password")
      end
    end

    context "with invalid parameters" do
      context "when email is missing" do
        let(:invalid_attributes) do
          {
            user: {
              email: "",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        it "does not create a user" do
          expect {
            post "/api/v1/auth/register", params: invalid_attributes
          }.not_to change(User, :count)
        end

        it "returns unprocessable entity status" do
          post "/api/v1/auth/register", params: invalid_attributes
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when email is invalid" do
        let(:invalid_attributes) do
          {
            user: {
              email: "invalid_email",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        it "does not create a user" do
          expect {
            post "/api/v1/auth/register", params: invalid_attributes
          }.not_to change(User, :count)
        end

        it "returns validation errors" do
          post "/api/v1/auth/register", params: invalid_attributes
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when email already exists" do
        before { create(:user, email: "existing@example.com") }

        let(:duplicate_email_attributes) do
          {
            user: {
              email: "existing@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        it "does not create a user" do
          expect {
            post "/api/v1/auth/register", params: duplicate_email_attributes
          }.not_to change(User, :count)
        end

        it "returns unprocessable entity status" do
          post "/api/v1/auth/register", params: duplicate_email_attributes
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error about email being taken" do
          post "/api/v1/auth/register", params: duplicate_email_attributes
          errors = json_response["errors"]
          expect(errors).to be_present
        end
      end

      context "when password is too short" do
        let(:short_password_attributes) do
          {
            user: {
              email: "user@example.com",
              password: "123",
              password_confirmation: "123"
            }
          }
        end

        it "does not create a user" do
          expect {
            post "/api/v1/auth/register", params: short_password_attributes
          }.not_to change(User, :count)
        end

        it "returns validation error" do
          post "/api/v1/auth/register", params: short_password_attributes
          errors = json_response["errors"]
          expect(errors).to be_present
        end
      end

      context "when password confirmation doesn't match" do
        let(:mismatched_password_attributes) do
          {
            user: {
              email: "user@example.com",
              password: "password123",
              password_confirmation: "different123"
            }
          }
        end

        it "does not create a user" do
          expect {
            post "/api/v1/auth/register", params: mismatched_password_attributes
          }.not_to change(User, :count)
        end

        it "returns validation error" do
          post "/api/v1/auth/register", params: mismatched_password_attributes
          errors = json_response["errors"]
          expect(errors).to be_present
        end
      end
    end

    context "with missing parameters" do
      it "returns bad request when user params are missing" do
        post "/api/v1/auth/register", params: {}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
