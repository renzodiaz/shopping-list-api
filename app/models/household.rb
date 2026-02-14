class Household < ApplicationRecord
  has_many :household_members, dependent: :destroy
  has_many :members, through: :household_members, source: :user
  has_one :owner_membership, -> { where(role: :owner) }, class_name: "HouseholdMember"
  has_one :owner, through: :owner_membership, source: :user

  has_many :invitations, dependent: :destroy
  has_many :shopping_lists, dependent: :destroy

  validates :name, presence: true
end
