class CreateInventoryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_items do |t|
      t.references :household, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.string :custom_name
      t.decimal :quantity, precision: 10, scale: 2, default: 0, null: false
      t.references :unit_type, null: true, foreign_key: true
      t.decimal :low_stock_threshold, precision: 10, scale: 2, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :inventory_items, [:household_id, :item_id], unique: true, where: "item_id IS NOT NULL"
    add_index :inventory_items, [:household_id, :custom_name], unique: true, where: "custom_name IS NOT NULL"
  end
end
