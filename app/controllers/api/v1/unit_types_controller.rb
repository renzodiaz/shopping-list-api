module Api::V1
  class UnitTypesController < BaseController
    def index
      unit_types = UnitType.order(:name).page(params[:page]).per(params[:per_page])
      serialize(unit_types, serializer: UnitTypeSerializer, options: { meta: pagination_meta(unit_types) })
    end

    def show
      unit_type = UnitType.find(params[:id])
      serialize(unit_type, serializer: UnitTypeSerializer)
    end
  end
end
