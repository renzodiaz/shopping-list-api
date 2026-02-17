module Api::V1::Households
  class ShoppingListsController < Api::V1::BaseController
    include HouseholdAuthorizable

    before_action :set_household
    before_action :authorize_member!
    before_action :authorize_owner!, only: %i[create update destroy complete duplicate]
    before_action :set_shopping_list, only: %i[show update destroy complete duplicate]

    def index
      shopping_lists = @household.shopping_lists.includes(:created_by)
      serialize(shopping_lists, serializer: ShoppingListSerializer, options: serializer_options)
    end

    def show
      serialize(@shopping_list, serializer: ShoppingListSerializer, options: show_serializer_options)
    end

    def create
      shopping_list = @household.shopping_lists.new(shopping_list_params)
      shopping_list.created_by = current_user

      if shopping_list.save
        serialize(shopping_list, serializer: ShoppingListSerializer, status: :created, options: serializer_options)
      else
        unprocessable_entity!(shopping_list)
      end
    end

    def update
      if @shopping_list.update(shopping_list_params)
        serialize(@shopping_list, serializer: ShoppingListSerializer, options: serializer_options)
      else
        unprocessable_entity!(@shopping_list)
      end
    end

    def destroy
      @shopping_list.destroy
      head :no_content
    end

    def complete
      if @shopping_list.completed?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Shopping list is already completed" }]
        }, status: :unprocessable_entity
      end

      @shopping_list.complete!(completed_by: current_user)
      serialize(@shopping_list, serializer: ShoppingListSerializer, options: serializer_options)
    end

    def duplicate
      new_list = @shopping_list.duplicate(new_name: params[:name])
      serialize(new_list, serializer: ShoppingListSerializer, status: :created, options: serializer_options)
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: format_errors(e.record.errors) }, status: :unprocessable_entity
    end

    private

    def set_household
      @household = Household.find(params[:household_id])
    end

    def set_shopping_list
      @shopping_list = @household.shopping_lists.find(params[:id])
    end

    def shopping_list_params
      params.require(:shopping_list).permit(:name, :status, :is_recurring, :recurrence_pattern, :recurrence_day)
    end

    def serializer_options
      { include: [:created_by] }
    end

    def show_serializer_options
      { include: [:created_by, :shopping_list_items] }
    end
  end
end
