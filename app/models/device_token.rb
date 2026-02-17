class DeviceToken < ApplicationRecord
  PLATFORMS = %w[ios android web].freeze

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: PLATFORMS }

  scope :ios, -> { where(platform: "ios") }
  scope :android, -> { where(platform: "android") }
  scope :web, -> { where(platform: "web") }
end
