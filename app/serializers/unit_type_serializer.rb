class UnitTypeSerializer
  include JSONAPI::Serializer
  attributes :name, :abbreviation, :created_at, :updated_at
end
