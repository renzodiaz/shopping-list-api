class InventoryItemSerializer
  include JSONAPI::Serializer

  attributes :quantity, :custom_name, :low_stock_threshold, :created_at, :updated_at

  attribute :display_name do |inventory_item|
    inventory_item.display_name
  end

  attribute :low_stock do |inventory_item|
    inventory_item.low_stock?
  end

  attribute :out_of_stock do |inventory_item|
    inventory_item.out_of_stock?
  end

  belongs_to :item, serializer: ItemSerializer
  belongs_to :unit_type, serializer: UnitTypeSerializer
  belongs_to :created_by, serializer: UserSerializer
end
