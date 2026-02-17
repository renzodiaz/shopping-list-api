class ShoppingList < ApplicationRecord
  RECURRENCE_PATTERNS = %w[daily weekly monthly].freeze

  belongs_to :household
  belongs_to :created_by, class_name: "User"
  belongs_to :parent_shopping_list, class_name: "ShoppingList", optional: true
  has_many :shopping_list_items, dependent: :destroy
  has_many :recurring_instances, class_name: "ShoppingList", foreign_key: :parent_shopping_list_id, dependent: :nullify

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :name, presence: true
  validates :recurrence_pattern, inclusion: { in: RECURRENCE_PATTERNS }, allow_nil: true
  validates :recurrence_day, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :recurrence_day_valid_for_pattern

  before_save :calculate_next_recurrence, if: :recurrence_changed?

  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: :completed) }
  scope :archived, -> { where(status: :archived) }
  scope :recurring, -> { where(is_recurring: true) }
  scope :due_for_recurrence, -> { recurring.where("next_recurrence_at <= ?", Time.current) }

  def complete!(completed_by: nil)
    update!(status: :completed, completed_at: Time.current)
    NotificationService.notify_list_completed(self, completed_by: completed_by) if completed_by
  end

  def duplicate(new_name: nil)
    new_list = dup
    new_list.name = new_name || "#{name} (Copy)"
    new_list.status = :active
    new_list.completed_at = nil
    new_list.is_recurring = false
    new_list.recurrence_pattern = nil
    new_list.recurrence_day = nil
    new_list.next_recurrence_at = nil
    new_list.parent_shopping_list = nil
    new_list.save!

    shopping_list_items.each do |item|
      new_item = item.dup
      new_item.shopping_list = new_list
      new_item.status = :pending
      new_item.checked_at = nil
      new_item.save!
    end

    new_list
  end

  def create_recurring_instance!
    return unless is_recurring?

    new_list = ShoppingList.new(
      household: household,
      created_by: created_by,
      name: "#{name} - #{Time.current.strftime('%Y-%m-%d')}",
      status: :active,
      parent_shopping_list: self
    )
    new_list.save!

    shopping_list_items.each do |item|
      new_item = item.dup
      new_item.shopping_list = new_list
      new_item.status = :pending
      new_item.checked_at = nil
      new_item.save!
    end

    # Update next recurrence
    calculate_next_recurrence
    save!

    NotificationService.notify_recurring_list_created(new_list)

    new_list
  end

  private

  def recurrence_changed?
    is_recurring_changed? || recurrence_pattern_changed? || recurrence_day_changed?
  end

  def calculate_next_recurrence
    return unless is_recurring? && recurrence_pattern.present?

    base_time = next_recurrence_at || Time.current
    base_time = Time.current if base_time < Time.current

    self.next_recurrence_at = case recurrence_pattern
    when "daily"
      next_daily_recurrence(base_time)
    when "weekly"
      next_weekly_recurrence(base_time)
    when "monthly"
      next_monthly_recurrence(base_time)
    end
  end

  def next_daily_recurrence(base_time)
    # Next day at midnight
    (base_time.to_date + 1.day).beginning_of_day
  end

  def next_weekly_recurrence(base_time)
    # recurrence_day: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    target_day = recurrence_day || 0
    current_day = base_time.wday
    days_until = (target_day - current_day) % 7
    days_until = 7 if days_until.zero? && base_time >= base_time.beginning_of_day
    (base_time.to_date + days_until.days).beginning_of_day
  end

  def next_monthly_recurrence(base_time)
    # recurrence_day: 1-31 (day of month)
    target_day = recurrence_day || 1
    next_month = base_time.next_month.beginning_of_month
    # Handle months with fewer days
    day = [ target_day, next_month.end_of_month.day ].min
    next_month.change(day: day).beginning_of_day
  end

  def recurrence_day_valid_for_pattern
    return unless is_recurring? && recurrence_pattern.present?

    case recurrence_pattern
    when "weekly"
      unless recurrence_day.nil? || recurrence_day.between?(0, 6)
        errors.add(:recurrence_day, "must be between 0 (Sunday) and 6 (Saturday) for weekly recurrence")
      end
    when "monthly"
      unless recurrence_day.nil? || recurrence_day.between?(1, 31)
        errors.add(:recurrence_day, "must be between 1 and 31 for monthly recurrence")
      end
    end
  end
end
