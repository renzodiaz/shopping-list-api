require "rails_helper"

RSpec.describe Item, type: :model do
  describe "validations" do
    subject { build(:item) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:category_id).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:default_unit_type).class_name("UnitType").optional }
  end

  describe "scopes" do
    let(:category) { create(:category) }
    let!(:default_item) { create(:item, :default, category: category) }
    let!(:custom_item) { create(:item, category: category) }

    describe ".defaults" do
      it "returns only default items" do
        expect(described_class.defaults).to contain_exactly(default_item)
      end
    end

    describe ".custom" do
      it "returns only custom items" do
        expect(described_class.custom).to contain_exactly(custom_item)
      end
    end

    describe ".search_by_name" do
      let!(:milk) { create(:item, name: "Milk", category: category) }
      let!(:almond_milk) { create(:item, name: "Almond Milk", category: category) }
      let!(:bread) { create(:item, name: "Bread", category: category) }

      it "finds items by partial name match" do
        expect(described_class.search_by_name("milk")).to contain_exactly(milk, almond_milk)
      end

      it "is case insensitive" do
        expect(described_class.search_by_name("MILK")).to contain_exactly(milk, almond_milk)
      end

      it "returns all items when query is blank" do
        expect(described_class.search_by_name("")).to include(milk, almond_milk, bread)
      end
    end

    describe ".by_category" do
      let(:other_category) { create(:category) }
      let!(:other_item) { create(:item, category: other_category) }

      it "filters items by category" do
        expect(described_class.by_category(category.id)).to contain_exactly(default_item, custom_item)
      end

      it "returns all items when category_id is blank" do
        expect(described_class.by_category(nil)).to include(default_item, custom_item, other_item)
      end
    end
  end

  describe "default values" do
    it "sets is_default to false by default" do
      item = described_class.new
      expect(item.is_default).to be false
    end
  end
end
