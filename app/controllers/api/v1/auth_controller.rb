module Api::V1
  class AuthController < BaseController
    skip_before_action :doorkeeper_authorize!, only: %i[register confirm resend_confirmation]
    skip_before_action :require_confirmed_email!, only: %i[register confirm resend_confirmation]

    def register
      user = User.new(user_params)

      if user.save
        otp = user.generate_email_confirmation_otp!
        EmailConfirmationMailer.confirmation_email(user, otp).deliver_later

        serialize(
          user,
          serializer: UserSerializer,
          status: :created
        )
      else
        unprocessable_entity!(user)
      end
    end

    def confirm
      user = User.find_by(email: params[:email]&.downcase)

      if user.nil?
        return render json: {
          errors: [{ status: "404", title: "Not Found", detail: "User not found" }]
        }, status: :not_found
      end

      if user.email_confirmed?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Email already confirmed" }]
        }, status: :unprocessable_entity
      end

      if user.otp_expired?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "OTP has expired. Please request a new one." }]
        }, status: :unprocessable_entity
      end

      if user.max_otp_attempts_exceeded?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Too many failed attempts. Please request a new OTP." }]
        }, status: :unprocessable_entity
      end

      if user.verify_email_confirmation_otp(params[:otp])
        render json: { message: "Email confirmed successfully" }, status: :ok
      else
        render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Invalid OTP" }]
        }, status: :unprocessable_entity
      end
    end

    def resend_confirmation
      user = User.find_by(email: params[:email]&.downcase)

      if user.nil?
        return render json: {
          errors: [{ status: "404", title: "Not Found", detail: "User not found" }]
        }, status: :not_found
      end

      if user.email_confirmed?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "Email already confirmed" }]
        }, status: :unprocessable_entity
      end

      unless user.can_resend_otp?
        return render json: {
          errors: [{ status: "429", title: "Too Many Requests", detail: "Please wait before requesting a new OTP" }]
        }, status: :too_many_requests
      end

      otp = user.generate_email_confirmation_otp!
      EmailConfirmationMailer.confirmation_email(user, otp).deliver_later

      render json: { message: "Confirmation email sent" }, status: :ok
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
