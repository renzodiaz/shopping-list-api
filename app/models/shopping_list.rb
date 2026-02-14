class ShoppingList < ApplicationRecord
  belongs_to :household
  belongs_to :created_by, class_name: "User"
  has_many :shopping_list_items, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :name, presence: true

  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: :completed) }
  scope :archived, -> { where(status: :archived) }

  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  def duplicate(new_name: nil)
    new_list = dup
    new_list.name = new_name || "#{name} (Copy)"
    new_list.status = :active
    new_list.completed_at = nil
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
end
