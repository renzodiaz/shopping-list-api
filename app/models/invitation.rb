class Invitation < ApplicationRecord
  belongs_to :household
  belongs_to :invited_by, class_name: "User"

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :not_already_member, on: :create

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  after_create :send_invitation_notification

  scope :active, -> { pending.where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def acceptable?
    pending? && !expired?
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end

  def not_already_member
    return unless household
    return unless HouseholdMember.exists?(household: household, user: User.find_by(email: email))

    errors.add(:email, "is already a member of this household")
  end

  def send_invitation_notification
    NotificationService.notify_invitation_received(self)
  end
end
