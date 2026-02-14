require "rails_helper"

RSpec.describe ShoppingListItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shopping_list) }
    it { is_expected.to belong_to(:item).optional }
    it { is_expected.to belong_to(:unit_type).optional }
    it { is_expected.to belong_to(:added_by).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }

    describe "item_or_custom_name_present" do
      let(:shopping_list) { create(:shopping_list) }
      let(:user) { create(:user) }

      it "is valid with an item" do
        item = create(:item)
        shopping_list_item = build(:shopping_list_item, shopping_list: shopping_list, item: item, custom_name: nil, added_by: user)
        expect(shopping_list_item).to be_valid
      end

      it "is valid with a custom name" do
        shopping_list_item = build(:shopping_list_item, shopping_list: shopping_list, item: nil, custom_name: "Custom Item", added_by: user)
        expect(shopping_list_item).to be_valid
      end

      it "is invalid without item or custom name" do
        shopping_list_item = build(:shopping_list_item, shopping_list: shopping_list, item: nil, custom_name: nil, added_by: user)
        expect(shopping_list_item).not_to be_valid
        expect(shopping_list_item.errors[:base]).to include("Either item or custom name must be provided")
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, checked: 1, not_in_stock: 2) }
  end

  describe "scopes" do
    let(:shopping_list) { create(:shopping_list) }
    let!(:pending_item) { create(:shopping_list_item, shopping_list: shopping_list, status: :pending) }
    let!(:checked_item) { create(:shopping_list_item, :checked, shopping_list: shopping_list) }
    let!(:not_in_stock_item) { create(:shopping_list_item, :not_in_stock, shopping_list: shopping_list) }

    describe ".pending" do
      it "returns only pending items" do
        expect(described_class.pending).to contain_exactly(pending_item)
      end
    end

    describe ".checked" do
      it "returns only checked items" do
        expect(described_class.checked).to contain_exactly(checked_item)
      end
    end

    describe ".not_in_stock" do
      it "returns only not_in_stock items" do
        expect(described_class.not_in_stock).to contain_exactly(not_in_stock_item)
      end
    end

    describe ".ordered" do
      it "returns pending items first, then others" do
        ordered = shopping_list.shopping_list_items.ordered
        expect(ordered.first).to eq(pending_item)
      end
    end
  end

  describe "#display_name" do
    let(:shopping_list) { create(:shopping_list) }

    it "returns item name when item is present" do
      item = create(:item, name: "Milk")
      shopping_list_item = create(:shopping_list_item, :with_item, shopping_list: shopping_list, item: item)
      expect(shopping_list_item.display_name).to eq("Milk")
    end

    it "returns custom name when item is not present" do
      shopping_list_item = create(:shopping_list_item, shopping_list: shopping_list, custom_name: "Custom Milk")
      expect(shopping_list_item.display_name).to eq("Custom Milk")
    end
  end

  describe "#check!" do
    let(:shopping_list_item) { create(:shopping_list_item, status: :pending) }

    it "marks the item as checked" do
      shopping_list_item.check!
      expect(shopping_list_item.reload.status).to eq("checked")
    end

    it "sets checked_at timestamp" do
      shopping_list_item.check!
      expect(shopping_list_item.reload.checked_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#uncheck!" do
    let(:shopping_list_item) { create(:shopping_list_item, :checked) }

    it "marks the item as pending" do
      shopping_list_item.uncheck!
      expect(shopping_list_item.reload.status).to eq("pending")
    end

    it "clears checked_at timestamp" do
      shopping_list_item.uncheck!
      expect(shopping_list_item.reload.checked_at).to be_nil
    end
  end

  describe "#mark_not_in_stock!" do
    let(:shopping_list_item) { create(:shopping_list_item, status: :pending) }

    it "marks the item as not_in_stock" do
      shopping_list_item.mark_not_in_stock!
      expect(shopping_list_item.reload.status).to eq("not_in_stock")
    end

    it "sets checked_at timestamp" do
      shopping_list_item.mark_not_in_stock!
      expect(shopping_list_item.reload.checked_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "position auto-assignment" do
    let(:shopping_list) { create(:shopping_list) }

    it "auto-assigns position on create" do
      item1 = create(:shopping_list_item, shopping_list: shopping_list)
      item2 = create(:shopping_list_item, shopping_list: shopping_list)
      expect(item1.position).to eq(1)
      expect(item2.position).to eq(2)
    end

    it "respects provided position" do
      item = create(:shopping_list_item, shopping_list: shopping_list, position: 10)
      expect(item.position).to eq(10)
    end
  end
end
