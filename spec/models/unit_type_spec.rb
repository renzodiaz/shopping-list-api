require "rails_helper"

RSpec.describe UnitType, type: :model do
  describe "validations" do
    subject { build(:unit_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_uniqueness_of(:abbreviation).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:items).with_foreign_key(:default_unit_type_id).dependent(:nullify) }
  end
end
