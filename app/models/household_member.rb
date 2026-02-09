class HouseholdMember < ApplicationRecord
  belongs_to :user
  belongs_to :household

  enum :role, { member: 0, owner: 1 }

  validates :user_id, uniqueness: { scope: :household_id, message: "is already a member of this household" }
  validate :only_one_owned_household, on: :create

  scope :owners, -> { where(role: :owner) }
  scope :members, -> { where(role: :member) }

  private

  def only_one_owned_household
    return unless owner?

    existing_ownership = HouseholdMember.owners.where(user_id: user_id).where.not(id: id).exists?
    return unless existing_ownership

    errors.add(:user, "can only own one household")
  end
end
