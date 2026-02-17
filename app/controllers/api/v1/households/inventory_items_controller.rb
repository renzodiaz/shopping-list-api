module Api::V1::Households
  class InventoryItemsController < Api::V1::BaseController
    include HouseholdAuthorizable

    before_action :set_household
    before_action :authorize_member!
    before_action :authorize_owner!, only: %i[create destroy]
    before_action :set_inventory_item, only: %i[show update destroy adjust]

    def index
      inventory_items = @household.inventory_items.includes(:item, :unit_type, :created_by)
      serialize(inventory_items, serializer: InventoryItemSerializer, options: serializer_options)
    end

    def show
      serialize(@inventory_item, serializer: InventoryItemSerializer, options: serializer_options)
    end

    def create
      inventory_item = @household.inventory_items.new(inventory_item_params)
      inventory_item.created_by = current_user

      if inventory_item.save
        serialize(inventory_item, serializer: InventoryItemSerializer, status: :created, options: serializer_options)
      else
        unprocessable_entity!(inventory_item)
      end
    end

    def update
      # Members can only update quantity, owners can update everything
      permitted_params = current_membership&.owner? ? inventory_item_params : quantity_only_params

      if @inventory_item.update(permitted_params)
        serialize(@inventory_item, serializer: InventoryItemSerializer, options: serializer_options)
      else
        unprocessable_entity!(@inventory_item)
      end
    end

    def destroy
      @inventory_item.destroy
      head :no_content
    end

    def adjust
      amount = params[:amount].to_d

      if amount.zero?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Amount cannot be zero" }]
        }, status: :unprocessable_entity
      end

      @inventory_item.adjust_quantity!(amount)
      serialize(@inventory_item, serializer: InventoryItemSerializer, options: serializer_options)
    end

    private

    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_inventory_item
      @inventory_item = @household.inventory_items.find(params[:id])
    end

    def inventory_item_params
      params.require(:inventory_item).permit(:item_id, :custom_name, :quantity, :unit_type_id, :low_stock_threshold)
    end

    def quantity_only_params
      params.require(:inventory_item).permit(:quantity)
    end

    def serializer_options
      { include: %i[item unit_type created_by] }
    end
  end
end
