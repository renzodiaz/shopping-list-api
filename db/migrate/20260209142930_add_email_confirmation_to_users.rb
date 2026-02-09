class AddEmailConfirmationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_confirmation_otp_digest, :string
    add_column :users, :email_confirmation_otp_sent_at, :datetime
    add_column :users, :email_confirmed_at, :datetime
    add_column :users, :email_confirmation_attempts, :integer, default: 0, null: false

    add_index :users, :email_confirmed_at
  end
end
