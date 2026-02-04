class CategorySerializer
  include JSONAPI::Serializer
  attributes :name, :description, :icon, :created_at, :updated_at
end
