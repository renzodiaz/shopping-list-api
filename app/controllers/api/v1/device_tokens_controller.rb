module Api::V1
  class DeviceTokensController < BaseController
    before_action :set_device_token, only: %i[destroy]

    def index
      device_tokens = current_user.device_tokens
      render json: { data: device_tokens.map { |dt| device_token_json(dt) } }
    end

    def create
      device_token = current_user.device_tokens.find_or_initialize_by(token: device_token_params[:token])
      device_token.assign_attributes(device_token_params)

      if device_token.save
        render json: { data: device_token_json(device_token) }, status: device_token.previously_new_record? ? :created : :ok
      else
        unprocessable_entity!(device_token)
      end
    end

    def destroy
      @device_token.destroy
      head :no_content
    end

    private

    def set_device_token
      @device_token = current_user.device_tokens.find(params[:id])
    end

    def device_token_params
      params.require(:device_token).permit(:token, :platform, :device_name)
    end

    def device_token_json(device_token)
      {
        id: device_token.id,
        type: "device_token",
        attributes: {
          token: device_token.token,
          platform: device_token.platform,
          device_name: device_token.device_name,
          created_at: device_token.created_at
        }
      }
    end
  end
end
