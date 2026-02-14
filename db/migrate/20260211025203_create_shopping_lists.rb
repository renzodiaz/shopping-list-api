class CreateShoppingLists < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_lists do |t|
      t.references :household, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :completed_at

      t.timestamps
    end

    add_index :shopping_lists, :status
  end
end
