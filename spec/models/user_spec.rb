require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid_email").for(:email) }
  end

  describe "associations" do
    it { is_expected.to have_many(:access_grants).dependent(:delete_all) }
    it { is_expected.to have_many(:access_tokens).dependent(:delete_all) }
  end

  describe "devise modules" do
    it "includes database_authenticatable" do
      expect(described_class.devise_modules).to include(:database_authenticatable)
    end

    it "includes registerable" do
      expect(described_class.devise_modules).to include(:registerable)
    end

    it "includes recoverable" do
      expect(described_class.devise_modules).to include(:recoverable)
    end

    it "includes rememberable" do
      expect(described_class.devise_modules).to include(:rememberable)
    end

    it "includes validatable" do
      expect(described_class.devise_modules).to include(:validatable)
    end
  end

  describe "password encryption" do
    it "encrypts the password" do
      user = create(:user, password: "secure_password", password_confirmation: "secure_password")
      expect(user.encrypted_password).to be_present
    end

    it "authenticates with valid password" do
      user = create(:user, password: "secure_password", password_confirmation: "secure_password")
      expect(user.valid_password?("secure_password")).to be true
    end

    it "does not authenticate with invalid password" do
      user = create(:user, password: "secure_password", password_confirmation: "secure_password")
      expect(user.valid_password?("wrong_password")).to be false
    end
  end

  describe "dependent destroy" do
    let(:user) { create(:user) }
    let(:application) { create(:oauth_application) }

    before do
      create(:access_token, resource_owner_id: user.id, application: application)
      create(:access_grant, resource_owner_id: user.id, application: application)
    end

    it "deletes associated access tokens when user is destroyed" do
      expect { user.destroy }.to change(Doorkeeper::AccessToken, :count).by(-1)
    end

    it "deletes associated access grants when user is destroyed" do
      expect { user.destroy }.to change(Doorkeeper::AccessGrant, :count).by(-1)
    end
  end

  describe "email confirmation" do
    let(:user) { create(:user, :unconfirmed) }

    describe "#generate_email_confirmation_otp!" do
      it "generates a 6-digit OTP" do
        otp = user.generate_email_confirmation_otp!
        expect(otp).to match(/^\d{6}$/)
      end

      it "stores the OTP digest" do
        user.generate_email_confirmation_otp!
        expect(user.email_confirmation_otp_digest).to be_present
      end

      it "sets the sent_at timestamp" do
        user.generate_email_confirmation_otp!
        expect(user.email_confirmation_otp_sent_at).to be_within(1.second).of(Time.current)
      end

      it "resets attempt counter" do
        user.update!(email_confirmation_attempts: 3)
        user.generate_email_confirmation_otp!
        expect(user.email_confirmation_attempts).to eq(0)
      end
    end

    describe "#verify_email_confirmation_otp" do
      let(:otp) { user.generate_email_confirmation_otp! }

      it "returns true for valid OTP" do
        expect(user.verify_email_confirmation_otp(otp)).to be true
      end

      it "confirms the email on success" do
        user.verify_email_confirmation_otp(otp)
        expect(user.email_confirmed?).to be true
      end

      it "returns false for invalid OTP" do
        user.generate_email_confirmation_otp!
        expect(user.verify_email_confirmation_otp("000000")).to be false
      end

      it "increments attempts on failure" do
        user.generate_email_confirmation_otp!
        user.verify_email_confirmation_otp("000000")
        expect(user.email_confirmation_attempts).to eq(1)
      end

      it "returns false when expired" do
        otp = user.generate_email_confirmation_otp!
        travel_to 11.minutes.from_now do
          expect(user.verify_email_confirmation_otp(otp)).to be false
        end
      end

      it "returns false when max attempts exceeded" do
        otp = user.generate_email_confirmation_otp!
        user.update!(email_confirmation_attempts: 5)
        expect(user.verify_email_confirmation_otp(otp)).to be false
      end
    end

    describe "#email_confirmed?" do
      it "returns false when email_confirmed_at is nil" do
        expect(user.email_confirmed?).to be false
      end

      it "returns true when email_confirmed_at is present" do
        user.update!(email_confirmed_at: Time.current)
        expect(user.email_confirmed?).to be true
      end
    end

    describe "#otp_expired?" do
      it "returns true when no OTP sent" do
        expect(user.otp_expired?).to be true
      end

      it "returns false within expiration window" do
        user.generate_email_confirmation_otp!
        expect(user.otp_expired?).to be false
      end

      it "returns true after expiration window" do
        user.generate_email_confirmation_otp!
        travel_to 11.minutes.from_now do
          expect(user.otp_expired?).to be true
        end
      end
    end

    describe "#can_resend_otp?" do
      it "returns true when no OTP sent" do
        expect(user.can_resend_otp?).to be true
      end

      it "returns false within cooldown period" do
        user.generate_email_confirmation_otp!
        expect(user.can_resend_otp?).to be false
      end

      it "returns true after cooldown period" do
        user.generate_email_confirmation_otp!
        travel_to 2.minutes.from_now do
          expect(user.can_resend_otp?).to be true
        end
      end
    end
  end
end
