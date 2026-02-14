class ShoppingListItemSerializer
  include JSONAPI::Serializer

  attributes :quantity, :status, :custom_name, :checked_at, :position, :created_at, :updated_at

  attribute :display_name do |item|
    item.display_name
  end

  belongs_to :item, serializer: ItemSerializer
  belongs_to :unit_type, serializer: UnitTypeSerializer
  belongs_to :added_by, serializer: UserSerializer
end
