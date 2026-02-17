class ShoppingListSerializer
  include JSONAPI::Serializer

  attributes :name, :status, :completed_at, :created_at, :updated_at,
             :is_recurring, :recurrence_pattern, :recurrence_day, :next_recurrence_at

  attribute :items_count do |shopping_list|
    shopping_list.shopping_list_items.count
  end

  attribute :pending_count do |shopping_list|
    shopping_list.shopping_list_items.pending.count
  end

  attribute :checked_count do |shopping_list|
    shopping_list.shopping_list_items.checked.count
  end

  belongs_to :created_by, serializer: UserSerializer
  belongs_to :household, serializer: HouseholdSerializer
  has_many :shopping_list_items, serializer: ShoppingListItemSerializer
end
