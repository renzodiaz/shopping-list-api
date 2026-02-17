class InventoryItem < ApplicationRecord
  belongs_to :household
  belongs_to :item, optional: true
  belongs_to :unit_type, optional: true
  belongs_to :created_by, class_name: "User"

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :item_or_custom_name_present
  validate :unique_item_in_household

  scope :low_stock, -> { where("quantity <= low_stock_threshold AND quantity > 0") }
  scope :out_of_stock, -> { where(quantity: 0) }
  scope :in_stock, -> { where("quantity > low_stock_threshold") }

  after_update :check_stock_levels, if: :saved_change_to_quantity?

  def display_name
    item&.name || custom_name
  end

  def low_stock?
    quantity <= low_stock_threshold && quantity > 0
  end

  def out_of_stock?
    quantity.zero?
  end

  def in_stock?
    quantity > low_stock_threshold
  end

  def adjust_quantity!(amount)
    new_quantity = quantity + amount
    new_quantity = 0 if new_quantity.negative?
    update!(quantity: new_quantity)
  end

  private

  def item_or_custom_name_present
    return if item_id.present? || custom_name.present?

    errors.add(:base, "Either item or custom name must be provided")
  end

  def unique_item_in_household
    return unless household_id.present?

    if item_id.present?
      existing = InventoryItem.where(household_id: household_id, item_id: item_id).where.not(id: id)
      errors.add(:item, "is already in this household's inventory") if existing.exists?
    elsif custom_name.present?
      existing = InventoryItem.where(household_id: household_id, custom_name: custom_name).where.not(id: id)
      errors.add(:custom_name, "is already in this household's inventory") if existing.exists?
    end
  end

  def check_stock_levels
    previous_quantity = quantity_before_last_save

    # Notify when going from in-stock to low-stock
    if low_stock? && previous_quantity > low_stock_threshold
      NotificationService.notify_low_stock(self)
    end

    # Notify when going out of stock
    if out_of_stock? && previous_quantity > 0
      NotificationService.notify_out_of_stock(self)
    end
  end
end
