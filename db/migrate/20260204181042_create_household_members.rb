class CreateHouseholdMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :household_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :household, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :household_members, %i[user_id household_id], unique: true
    add_index :household_members, :role
  end
end
