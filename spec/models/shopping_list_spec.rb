require "rails_helper"

RSpec.describe ShoppingList, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:household) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to have_many(:shopping_list_items).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, completed: 1, archived: 2) }
  end

  describe "scopes" do
    let!(:active_list) { create(:shopping_list, status: :active) }
    let!(:completed_list) { create(:shopping_list, :completed) }
    let!(:archived_list) { create(:shopping_list, :archived) }

    describe ".active" do
      it "returns only active lists" do
        expect(described_class.active).to contain_exactly(active_list)
      end
    end

    describe ".completed" do
      it "returns only completed lists" do
        expect(described_class.completed).to contain_exactly(completed_list)
      end
    end

    describe ".archived" do
      it "returns only archived lists" do
        expect(described_class.archived).to contain_exactly(archived_list)
      end
    end
  end

  describe "#complete!" do
    let(:shopping_list) { create(:shopping_list, status: :active) }

    it "marks the list as completed" do
      shopping_list.complete!
      expect(shopping_list.reload.status).to eq("completed")
    end

    it "sets completed_at timestamp" do
      shopping_list.complete!
      expect(shopping_list.reload.completed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#duplicate" do
    let(:shopping_list) { create(:shopping_list, name: "Weekly Groceries") }
    let!(:item1) { create(:shopping_list_item, shopping_list: shopping_list, custom_name: "Milk") }
    let!(:item2) { create(:shopping_list_item, shopping_list: shopping_list, custom_name: "Bread", status: :checked) }

    it "creates a new list with default copy name" do
      new_list = shopping_list.duplicate
      expect(new_list.name).to eq("Weekly Groceries (Copy)")
    end

    it "creates a new list with custom name" do
      new_list = shopping_list.duplicate(new_name: "Next Week")
      expect(new_list.name).to eq("Next Week")
    end

    it "sets the new list as active" do
      shopping_list.update!(status: :completed)
      new_list = shopping_list.duplicate
      expect(new_list.status).to eq("active")
    end

    it "duplicates all items" do
      new_list = shopping_list.duplicate
      expect(new_list.shopping_list_items.count).to eq(2)
    end

    it "resets item statuses to pending" do
      new_list = shopping_list.duplicate
      expect(new_list.shopping_list_items.pluck(:status).uniq).to eq(["pending"])
    end

    it "clears checked_at on duplicated items" do
      new_list = shopping_list.duplicate
      expect(new_list.shopping_list_items.pluck(:checked_at).uniq).to eq([nil])
    end
  end
end
