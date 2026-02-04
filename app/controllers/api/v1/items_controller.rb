module Api::V1
  class ItemsController < BaseController
    before_action :set_item, only: %i[show update destroy]
    before_action :ensure_custom_item, only: %i[update destroy]

    def index
      items = Item.includes(:category, :default_unit_type)
                  .search_by_name(params[:search])
                  .by_category(params[:category_id])
                  .order(:name)
                  .page(params[:page])
                  .per(params[:per_page])

      serialize(items, serializer: ItemSerializer, options: serializer_options(items))
    end

    def show
      serialize(@item, serializer: ItemSerializer, options: { include: %i[category default_unit_type] })
    end

    def create
      item = Item.new(item_params)

      if item.save
        serialize(item, serializer: ItemSerializer, status: :created, options: { include: %i[category default_unit_type] })
      else
        unprocessable_entity!(item)
      end
    end

    def update
      if @item.update(item_params)
        serialize(@item, serializer: ItemSerializer, options: { include: %i[category default_unit_type] })
      else
        unprocessable_entity!(@item)
      end
    end

    def destroy
      @item.destroy
      head :no_content
    end

    private

    def set_item
      @item = Item.find(params[:id])
    end

    def ensure_custom_item
      return unless @item.is_default?

      render json: {
        errors: [
          {
            status: "403",
            title: "Forbidden",
            detail: "Cannot modify default items"
          }
        ]
      }, status: :forbidden
    end

    def item_params
      params.require(:item).permit(:name, :description, :brand, :icon, :category_id, :default_unit_type_id)
    end

    def serializer_options(items)
      {
        include: %i[category default_unit_type],
        meta: pagination_meta(items)
      }
    end
  end
end
