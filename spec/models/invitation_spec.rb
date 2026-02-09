require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:household) }
    it { is_expected.to belong_to(:invited_by).class_name("User") }
  end

  describe "validations" do
    subject { create(:invitation) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid").for(:email) }

    # Note: token and expires_at presence are ensured by callbacks, not validations
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, accepted: 1, declined: 2) }
  end

  describe "callbacks" do
    describe "generate_token" do
      it "generates a token before validation on create" do
        invitation = build(:invitation, token: nil)
        invitation.valid?
        expect(invitation.token).to be_present
      end

      it "does not overwrite existing token" do
        invitation = build(:invitation, token: "existing-token")
        invitation.valid?
        expect(invitation.token).to eq("existing-token")
      end
    end

    describe "set_expiration" do
      it "sets expires_at to approximately 7 days from now" do
        invitation = build(:invitation, expires_at: nil)
        invitation.valid?
        expect(invitation.expires_at).to be_within(1.minute).of(7.days.from_now)
      end

      it "does not overwrite existing expires_at" do
        custom_expiry = 3.days.from_now
        invitation = build(:invitation, expires_at: custom_expiry)
        invitation.valid?
        expect(invitation.expires_at).to be_within(1.second).of(custom_expiry)
      end
    end
  end

  describe "scopes" do
    let(:household) { create(:household) }

    describe ".active" do
      let!(:active_invitation) { create(:invitation, household: household) }
      let!(:expired_invitation) { create(:invitation, :expired, household: household) }
      let!(:accepted_invitation) { create(:invitation, :accepted, household: household) }

      it "returns only pending and non-expired invitations" do
        expect(described_class.active).to contain_exactly(active_invitation)
      end
    end

    describe ".expired" do
      let!(:active_invitation) { create(:invitation, household: household) }
      let!(:expired_invitation) { create(:invitation, :expired, household: household) }

      it "returns only expired invitations" do
        expect(described_class.expired).to contain_exactly(expired_invitation)
      end
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      invitation = build(:invitation, :expired)
      expect(invitation.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      invitation = build(:invitation)
      expect(invitation.expired?).to be false
    end
  end

  describe "#acceptable?" do
    it "returns true when pending and not expired" do
      invitation = build(:invitation)
      expect(invitation.acceptable?).to be true
    end

    it "returns false when expired" do
      invitation = build(:invitation, :expired)
      expect(invitation.acceptable?).to be false
    end

    it "returns false when already accepted" do
      invitation = build(:invitation, :accepted)
      expect(invitation.acceptable?).to be false
    end

    it "returns false when declined" do
      invitation = build(:invitation, :declined)
      expect(invitation.acceptable?).to be false
    end
  end

  describe "not_already_member validation" do
    let(:household) { create(:household) }
    let(:user) { create(:user, email: "member@example.com") }

    before { create(:household_member, user: user, household: household) }

    it "prevents inviting existing members" do
      invitation = build(:invitation, household: household, email: "member@example.com")
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("is already a member of this household")
    end

    it "allows inviting non-members" do
      invitation = build(:invitation, household: household, email: "new@example.com")
      expect(invitation).to be_valid
    end
  end
end
