class EmailConfirmationMailer < ApplicationMailer
  def confirmation_email(user, otp)
    @user = user
    @otp = otp
    @expires_in = User::OTP_EXPIRATION_TIME.to_i / 60

    mail(
      to: @user.email,
      subject: "Confirm your email address"
    )
  end
end
