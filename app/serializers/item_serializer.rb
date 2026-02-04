class ItemSerializer
  include JSONAPI::Serializer

  attributes :name, :description, :brand, :icon, :is_default, :created_at, :updated_at

  belongs_to :category, serializer: CategorySerializer
  belongs_to :default_unit_type, serializer: UnitTypeSerializer
end
