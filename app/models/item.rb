class Item < ApplicationRecord
  belongs_to :category
  belongs_to :default_unit_type, class_name: "UnitType", optional: true

  validates :name, presence: true, uniqueness: { scope: :category_id, case_sensitive: false }

  scope :defaults, -> { where(is_default: true) }
  scope :custom, -> { where(is_default: false) }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
end
