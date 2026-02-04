class UnitType < ApplicationRecord
  has_many :items, foreign_key: :default_unit_type_id, dependent: :nullify, inverse_of: :default_unit_type

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :abbreviation, presence: true, uniqueness: { case_sensitive: false }
end
