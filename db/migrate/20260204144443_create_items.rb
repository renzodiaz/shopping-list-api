class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.text :description
      t.string :brand
      t.string :icon
      t.boolean :is_default, null: false, default: false
      t.references :category, null: false, foreign_key: true
      t.references :default_unit_type, null: true, foreign_key: { to_table: :unit_types }

      t.timestamps
    end

    add_index :items, %i[name category_id], unique: true
    add_index :items, :is_default
  end
end
