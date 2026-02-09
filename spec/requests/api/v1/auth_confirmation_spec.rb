require "rails_helper"

RSpec.describe "Api::V1::Auth Email Confirmation", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_attributes) do
      {
        user: {
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates unconfirmed user" do
      post "/api/v1/auth/register", params: valid_attributes
      expect(User.last.email_confirmed?).to be false
    end

    it "sends confirmation email" do
      expect {
        post "/api/v1/auth/register", params: valid_attributes
      }.to have_enqueued_mail(EmailConfirmationMailer, :confirmation_email)
    end

    it "returns email_confirmed as false" do
      post "/api/v1/auth/register", params: valid_attributes
      expect(json_response.dig("data", "attributes", "email_confirmed")).to be false
    end

    it "generates an OTP for the user" do
      post "/api/v1/auth/register", params: valid_attributes
      expect(User.last.email_confirmation_otp_digest).to be_present
    end
  end

  describe "POST /api/v1/auth/confirm" do
    let(:user) { create(:user, :unconfirmed) }
    let!(:otp) { user.generate_email_confirmation_otp! }

    context "with valid OTP" do
      it "confirms the email" do
        post "/api/v1/auth/confirm", params: { email: user.email, otp: otp }
        expect(response).to have_http_status(:ok)
        expect(user.reload.email_confirmed?).to be true
      end

      it "returns success message" do
        post "/api/v1/auth/confirm", params: { email: user.email, otp: otp }
        expect(json_response["message"]).to eq("Email confirmed successfully")
      end
    end

    context "with invalid OTP" do
      it "returns unprocessable entity" do
        post "/api/v1/auth/confirm", params: { email: user.email, otp: "000000" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to eq("Invalid OTP")
      end

      it "does not confirm the email" do
        post "/api/v1/auth/confirm", params: { email: user.email, otp: "000000" }
        expect(user.reload.email_confirmed?).to be false
      end
    end

    context "with expired OTP" do
      it "returns unprocessable entity" do
        travel_to 11.minutes.from_now do
          post "/api/v1/auth/confirm", params: { email: user.email, otp: otp }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"].first["detail"]).to include("expired")
        end
      end
    end

    context "when max attempts exceeded" do
      before { user.update!(email_confirmation_attempts: 5) }

      it "returns unprocessable entity" do
        post "/api/v1/auth/confirm", params: { email: user.email, otp: otp }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("Too many")
      end
    end

    context "when email already confirmed" do
      let(:confirmed_user) { create(:user, :confirmed) }

      it "returns unprocessable entity" do
        post "/api/v1/auth/confirm", params: { email: confirmed_user.email, otp: "123456" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("already confirmed")
      end
    end

    context "with non-existent user" do
      it "returns not found" do
        post "/api/v1/auth/confirm", params: { email: "nonexistent@example.com", otp: "123456" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/auth/resend_confirmation" do
    let(:user) { create(:user, :unconfirmed) }

    it "sends new confirmation email" do
      expect {
        post "/api/v1/auth/resend_confirmation", params: { email: user.email }
      }.to have_enqueued_mail(EmailConfirmationMailer, :confirmation_email)
    end

    it "returns success message" do
      post "/api/v1/auth/resend_confirmation", params: { email: user.email }
      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq("Confirmation email sent")
    end

    context "when within cooldown period" do
      before { user.generate_email_confirmation_otp! }

      it "returns too_many_requests" do
        post "/api/v1/auth/resend_confirmation", params: { email: user.email }
        expect(response).to have_http_status(:too_many_requests)
        expect(json_response["errors"].first["detail"]).to include("wait")
      end
    end

    context "after cooldown period" do
      before { user.generate_email_confirmation_otp! }

      it "works after cooldown" do
        travel_to 2.minutes.from_now do
          post "/api/v1/auth/resend_confirmation", params: { email: user.email }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when email already confirmed" do
      let(:confirmed_user) { create(:user, :confirmed) }

      it "returns unprocessable entity" do
        post "/api/v1/auth/resend_confirmation", params: { email: confirmed_user.email }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["detail"]).to include("already confirmed")
      end
    end

    context "with non-existent user" do
      it "returns not found" do
        post "/api/v1/auth/resend_confirmation", params: { email: "nonexistent@example.com" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "accessing protected endpoints" do
    let(:application) { create(:oauth_application) }

    context "with unconfirmed user" do
      let(:unconfirmed_user) { create(:user, :unconfirmed) }
      let(:access_token) { create(:access_token, resource_owner_id: unconfirmed_user.id, application: application) }
      let(:headers) { auth_header(access_token.token) }

      it "returns forbidden for protected endpoints" do
        get "/api/v1/households", headers: headers
        expect(response).to have_http_status(:forbidden)
        expect(json_response["errors"].first["code"]).to eq("email_not_confirmed")
      end
    end

    context "with confirmed user" do
      let(:confirmed_user) { create(:user, :confirmed) }
      let(:access_token) { create(:access_token, resource_owner_id: confirmed_user.id, application: application) }
      let(:headers) { auth_header(access_token.token) }

      it "allows access to protected endpoints" do
        get "/api/v1/households", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "token issuance" do
    let(:application) { create(:oauth_application) }

    context "with unconfirmed user" do
      let!(:unconfirmed_user) { create(:user, :unconfirmed, email: "unconfirmed@example.com") }

      it "does not issue token for unconfirmed user" do
        post "/oauth/token", params: {
          grant_type: "password",
          username: unconfirmed_user.email,
          password: "password123",
          client_id: application.uid,
          client_secret: application.secret
        }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with confirmed user" do
      let!(:confirmed_user) { create(:user, :confirmed, email: "confirmed@example.com") }

      it "issues token for confirmed user" do
        post "/oauth/token", params: {
          grant_type: "password",
          username: confirmed_user.email,
          password: "password123",
          client_id: application.uid,
          client_secret: application.secret
        }
        expect(response).to have_http_status(:ok)
        expect(json_response["access_token"]).to be_present
      end
    end
  end
end
