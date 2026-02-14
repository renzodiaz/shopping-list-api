module Api::V1
  class ShoppingListItemsController < BaseController
    include HouseholdAuthorizable

    before_action :set_shopping_list
    before_action :authorize_member!
    before_action :set_shopping_list_item, only: %i[update destroy check uncheck not_in_stock]

    def index
      items = @shopping_list.shopping_list_items.ordered.includes(:item, :unit_type, :added_by)
      serialize(items, serializer: ShoppingListItemSerializer, options: serializer_options)
    end

    def create
      item = @shopping_list.shopping_list_items.new(shopping_list_item_params)
      item.added_by = current_user

      if item.save
        serialize(item, serializer: ShoppingListItemSerializer, status: :created, options: serializer_options)
      else
        unprocessable_entity!(item)
      end
    end

    def update
      if @shopping_list_item.update(shopping_list_item_params)
        serialize(@shopping_list_item, serializer: ShoppingListItemSerializer, options: serializer_options)
      else
        unprocessable_entity!(@shopping_list_item)
      end
    end

    def destroy
      @shopping_list_item.destroy
      head :no_content
    end

    def check
      @shopping_list_item.check!
      serialize(@shopping_list_item, serializer: ShoppingListItemSerializer, options: serializer_options)
    end

    def uncheck
      @shopping_list_item.uncheck!
      serialize(@shopping_list_item, serializer: ShoppingListItemSerializer, options: serializer_options)
    end

    def not_in_stock
      @shopping_list_item.mark_not_in_stock!
      serialize(@shopping_list_item, serializer: ShoppingListItemSerializer, options: serializer_options)
    end

    private

    def set_shopping_list
      @shopping_list = ShoppingList.find(params[:shopping_list_id])
      @household = @shopping_list.household
    end

    def set_shopping_list_item
      @shopping_list_item = @shopping_list.shopping_list_items.find(params[:id])
    end

    def shopping_list_item_params
      params.require(:item).permit(:item_id, :custom_name, :quantity, :unit_type_id)
    end

    def serializer_options
      { include: %i[item unit_type added_by] }
    end
  end
end
