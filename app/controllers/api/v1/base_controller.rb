module Api::V1
  class BaseController < ApplicationController
    before_action :doorkeeper_authorize!
    before_action :require_confirmed_email!

    rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found

    protected

    def require_confirmed_email!
      return if current_user&.email_confirmed?

      render json: {
        errors: [{
          status: "403",
          title: "Forbidden",
          code: "email_not_confirmed",
          detail: "Please confirm your email address to access this resource"
        }]
      }, status: :forbidden
    end

    def current_user
      return unless doorkeeper_token

      @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

    def unprocessable_entity!(resource)
      render json: {
        errors: format_errors(resource.errors)
      }, status: :unprocessable_entity
    end

    def serialize(resource, serializer:, status: :ok, options: {})
      render json: serializer.new(resource, options).serializable_hash,
             status: status
    end

    def resource_not_found
      render json: {
        errors: [
          {
            status: "404",
            title: "Not Found",
            detail: "Resource not found"
          }
        ]
      }, status: :not_found
    end

    def pagination_meta(collection)
      {
        current_page: collection.current_page,
        next_page: collection.next_page,
        prev_page: collection.prev_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count
      }
    end

    private

    def format_errors(errors)
      errors.map do |attr, message|
        {
          status: "422",
          source: { pointer: "/data/attributes/#{attr}" },
          title: "Invalid Attribute",
          detail: message
        }
      end
    end
  end
end
