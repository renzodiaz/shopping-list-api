class CreateShoppingListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.string :custom_name
      t.decimal :quantity, precision: 10, scale: 2, default: 1, null: false
      t.references :unit_type, null: true, foreign_key: true
      t.integer :status, default: 0, null: false
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.datetime :checked_at
      t.integer :position

      t.timestamps
    end

    add_index :shopping_list_items, :status
    add_index :shopping_list_items, [:shopping_list_id, :position]
  end
end
