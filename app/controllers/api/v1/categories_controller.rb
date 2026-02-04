module Api::V1
  class CategoriesController < BaseController
    def index
      categories = Category.order(:name).page(params[:page]).per(params[:per_page])
      serialize(categories, serializer: CategorySerializer, options: { meta: pagination_meta(categories) })
    end

    def show
      category = Category.find(params[:id])
      serialize(category, serializer: CategorySerializer)
    end
  end
end
