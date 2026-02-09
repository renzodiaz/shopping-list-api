require "rails_helper"

RSpec.describe Household, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:household_members).dependent(:destroy) }
    it { is_expected.to have_many(:members).through(:household_members) }
    it { is_expected.to have_one(:owner_membership).class_name("HouseholdMember") }
    it { is_expected.to have_one(:owner).through(:owner_membership) }
    it { is_expected.to have_many(:invitations).dependent(:destroy) }
  end
end
