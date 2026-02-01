module Api::V1
  class AuthController < BaseController
    skip_before_action :doorkeeper_authorize!, only: [:register]

    def register
      user = User.new(user_params)

      if user.save
        serialize(
          user,
          serializer: UserSerializer,
          status: :created
        )
      else
        unprocessable_entity!(user)
      end
    end

    private

    def user_params
      params.require(:user).permit(
        :email,
        :password,
        :password_confirmation
      )
    end
  end
end
