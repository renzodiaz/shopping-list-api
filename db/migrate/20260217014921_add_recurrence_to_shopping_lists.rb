class AddRecurrenceToShoppingLists < ActiveRecord::Migration[8.0]
  def change
    add_column :shopping_lists, :is_recurring, :boolean, default: false, null: false
    add_column :shopping_lists, :recurrence_pattern, :string
    add_column :shopping_lists, :recurrence_day, :integer
    add_column :shopping_lists, :next_recurrence_at, :datetime
    add_reference :shopping_lists, :parent_shopping_list, null: true, foreign_key: { to_table: :shopping_lists }

    add_index :shopping_lists, :next_recurrence_at, where: "is_recurring = true AND next_recurrence_at IS NOT NULL"
  end
end
