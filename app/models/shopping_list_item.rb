class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list
  belongs_to :item, optional: true
  belongs_to :unit_type, optional: true
  belongs_to :added_by, class_name: "User"

  enum :status, { pending: 0, checked: 1, not_in_stock: 2 }

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :item_or_custom_name_present

  before_create :set_position

  scope :pending, -> { where(status: :pending) }
  scope :checked, -> { where(status: :checked) }
  scope :not_in_stock, -> { where(status: :not_in_stock) }
  scope :ordered, -> { order(Arel.sql("CASE WHEN status = 0 THEN 0 ELSE 1 END"), :position) }

  def display_name
    item&.name || custom_name
  end

  def check!
    update!(status: :checked, checked_at: Time.current)
  end

  def uncheck!
    update!(status: :pending, checked_at: nil)
  end

  def mark_not_in_stock!
    update!(status: :not_in_stock, checked_at: Time.current)
  end

  private

  def item_or_custom_name_present
    return if item_id.present? || custom_name.present?

    errors.add(:base, "Either item or custom name must be provided")
  end

  def set_position
    return if position.present?

    max_position = shopping_list.shopping_list_items.maximum(:position) || 0
    self.position = max_position + 1
  end
end
