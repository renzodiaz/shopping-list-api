require "rails_helper"

RSpec.describe Category, type: :model do
  describe "validations" do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:items).dependent(:restrict_with_error) }
  end
end
