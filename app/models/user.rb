class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # OTP Configuration
  OTP_EXPIRATION_TIME = 10.minutes
  MAX_OTP_ATTEMPTS = 5
  OTP_RESEND_COOLDOWN = 1.minute

  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :household_members, dependent: :destroy
  has_many :households, through: :household_members
  has_one :owned_membership, -> { where(role: :owner) }, class_name: "HouseholdMember", dependent: :destroy
  has_one :owned_household, through: :owned_membership, source: :household

  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :destroy

  def generate_email_confirmation_otp!
    otp = SecureRandom.random_number(100_000..999_999).to_s
    update!(
      email_confirmation_otp_digest: BCrypt::Password.create(otp),
      email_confirmation_otp_sent_at: Time.current,
      email_confirmation_attempts: 0
    )
    otp
  end

  def verify_email_confirmation_otp(otp)
    return false if email_confirmation_otp_digest.blank?
    return false if otp_expired?
    return false if max_otp_attempts_exceeded?

    if BCrypt::Password.new(email_confirmation_otp_digest) == otp
      confirm_email!
      true
    else
      increment!(:email_confirmation_attempts)
      false
    end
  end

  def confirm_email!
    update!(
      email_confirmed_at: Time.current,
      email_confirmation_otp_digest: nil,
      email_confirmation_otp_sent_at: nil,
      email_confirmation_attempts: 0
    )
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def otp_expired?
    return true if email_confirmation_otp_sent_at.blank?
    email_confirmation_otp_sent_at < OTP_EXPIRATION_TIME.ago
  end

  def max_otp_attempts_exceeded?
    email_confirmation_attempts >= MAX_OTP_ATTEMPTS
  end

  def can_resend_otp?
    return true if email_confirmation_otp_sent_at.blank?
    email_confirmation_otp_sent_at < OTP_RESEND_COOLDOWN.ago
  end
end
