class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :household, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, :status
    add_index :invitations, %i[household_id email], unique: true, where: "status = 0", name: "index_invitations_on_household_and_email_pending"
  end
end
