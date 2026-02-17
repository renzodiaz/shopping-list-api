require "rails_helper"

RSpec.describe InventoryItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:household) }
    it { is_expected.to belong_to(:item).optional }
    it { is_expected.to belong_to(:unit_type).optional }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:low_stock_threshold) }
    it { is_expected.to validate_numericality_of(:low_stock_threshold).is_greater_than_or_equal_to(0) }

    describe "item_or_custom_name_present" do
      let(:household) { create(:household) }
      let(:user) { create(:user) }

      it "is valid with an item" do
        item = create(:item)
        inventory_item = build(:inventory_item, household: household, item: item, custom_name: nil, created_by: user)
        expect(inventory_item).to be_valid
      end

      it "is valid with a custom name" do
        inventory_item = build(:inventory_item, household: household, item: nil, custom_name: "Custom Item", created_by: user)
        expect(inventory_item).to be_valid
      end

      it "is invalid without item or custom name" do
        inventory_item = build(:inventory_item, household: household, item: nil, custom_name: nil, created_by: user)
        expect(inventory_item).not_to be_valid
        expect(inventory_item.errors[:base]).to include("Either item or custom name must be provided")
      end
    end

    describe "unique_item_in_household" do
      let(:household) { create(:household) }
      let(:user) { create(:user) }
      let(:item) { create(:item) }

      it "prevents duplicate catalog items in same household" do
        create(:inventory_item, :with_item, household: household, item: item, created_by: user)
        duplicate = build(:inventory_item, :with_item, household: household, item: item, created_by: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:item]).to include("is already in this household's inventory")
      end

      it "allows same item in different households" do
        other_household = create(:household)
        create(:inventory_item, :with_item, household: household, item: item, created_by: user)
        other_item = build(:inventory_item, :with_item, household: other_household, item: item, created_by: user)
        expect(other_item).to be_valid
      end

      it "prevents duplicate custom names in same household" do
        create(:inventory_item, household: household, custom_name: "My Item", created_by: user)
        duplicate = build(:inventory_item, household: household, custom_name: "My Item", created_by: user)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "scopes" do
    let(:household) { create(:household) }
    let!(:in_stock_item) { create(:inventory_item, household: household, quantity: 10, low_stock_threshold: 2) }
    let!(:low_stock_item) { create(:inventory_item, :low_stock, household: household) }
    let!(:out_of_stock_item) { create(:inventory_item, :out_of_stock, household: household) }

    describe ".low_stock" do
      it "returns items where quantity <= threshold and quantity > 0" do
        expect(described_class.low_stock).to contain_exactly(low_stock_item)
      end
    end

    describe ".out_of_stock" do
      it "returns items where quantity is 0" do
        expect(described_class.out_of_stock).to contain_exactly(out_of_stock_item)
      end
    end

    describe ".in_stock" do
      it "returns items where quantity > threshold" do
        expect(described_class.in_stock).to contain_exactly(in_stock_item)
      end
    end
  end

  describe "#display_name" do
    let(:household) { create(:household) }

    it "returns item name when item is present" do
      item = create(:item, name: "Milk")
      inventory_item = create(:inventory_item, :with_item, household: household, item: item)
      expect(inventory_item.display_name).to eq("Milk")
    end

    it "returns custom name when item is not present" do
      inventory_item = create(:inventory_item, household: household, custom_name: "Custom Milk")
      expect(inventory_item.display_name).to eq("Custom Milk")
    end
  end

  describe "#low_stock?" do
    it "returns true when quantity <= threshold and > 0" do
      inventory_item = build(:inventory_item, quantity: 2, low_stock_threshold: 5)
      expect(inventory_item.low_stock?).to be true
    end

    it "returns false when quantity > threshold" do
      inventory_item = build(:inventory_item, quantity: 10, low_stock_threshold: 5)
      expect(inventory_item.low_stock?).to be false
    end

    it "returns false when quantity is 0" do
      inventory_item = build(:inventory_item, quantity: 0, low_stock_threshold: 5)
      expect(inventory_item.low_stock?).to be false
    end
  end

  describe "#out_of_stock?" do
    it "returns true when quantity is 0" do
      inventory_item = build(:inventory_item, quantity: 0)
      expect(inventory_item.out_of_stock?).to be true
    end

    it "returns false when quantity > 0" do
      inventory_item = build(:inventory_item, quantity: 1)
      expect(inventory_item.out_of_stock?).to be false
    end
  end

  describe "#adjust_quantity!" do
    let(:inventory_item) { create(:inventory_item, quantity: 10) }

    it "increases quantity by positive amount" do
      inventory_item.adjust_quantity!(5)
      expect(inventory_item.quantity).to eq(15)
    end

    it "decreases quantity by negative amount" do
      inventory_item.adjust_quantity!(-3)
      expect(inventory_item.quantity).to eq(7)
    end

    it "does not go below zero" do
      inventory_item.adjust_quantity!(-20)
      expect(inventory_item.quantity).to eq(0)
    end
  end
end
