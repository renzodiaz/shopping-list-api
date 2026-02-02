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
end
