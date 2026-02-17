class Notification < ApplicationRecord
  TYPES = %w[
    low_stock
    out_of_stock
    list_completed
    item_checked
    invitation_received
    invitation_accepted
    member_joined
    member_left
    recurring_list_created
  ].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end
end
