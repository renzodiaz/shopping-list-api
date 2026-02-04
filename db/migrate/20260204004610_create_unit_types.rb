class CreateUnitTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :unit_types do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false

      t.timestamps
    end

    add_index :unit_types, :name, unique: true
    add_index :unit_types, :abbreviation, unique: true
  end
end
