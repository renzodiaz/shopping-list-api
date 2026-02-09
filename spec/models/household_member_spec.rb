require "rails_helper"

RSpec.describe HouseholdMember, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:household) }
  end

  describe "validations" do
    subject { build(:household_member) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:household_id).with_message("is already a member of this household") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(member: 0, owner: 1) }
  end

  describe "scopes" do
    let(:household) { create(:household) }
    let!(:owner_member) { create(:household_member, :owner, household: household) }
    let!(:regular_member) { create(:household_member, household: household) }

    describe ".owners" do
      it "returns only owner members" do
        expect(described_class.owners).to contain_exactly(owner_member)
      end
    end

    describe ".members" do
      it "returns only regular members" do
        expect(described_class.members).to contain_exactly(regular_member)
      end
    end
  end

  describe "only_one_owned_household validation" do
    let(:user) { create(:user) }
    let(:household1) { create(:household) }
    let(:household2) { create(:household) }

    context "when user already owns a household" do
      before { create(:household_member, :owner, user: user, household: household1) }

      it "prevents creating another owner membership" do
        new_membership = build(:household_member, :owner, user: user, household: household2)
        expect(new_membership).not_to be_valid
        expect(new_membership.errors[:user]).to include("can only own one household")
      end

      it "allows creating a member membership" do
        new_membership = build(:household_member, user: user, household: household2)
        expect(new_membership).to be_valid
      end
    end

    context "when user does not own any household" do
      it "allows creating an owner membership" do
        new_membership = build(:household_member, :owner, user: user, household: household1)
        expect(new_membership).to be_valid
      end
    end
  end
end
