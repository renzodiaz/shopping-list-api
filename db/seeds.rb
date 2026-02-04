# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Categories
categories = [
  { name: "Dairy", description: "Milk, cheese, yogurt, and other dairy products" },
  { name: "Produce", description: "Fresh vegetables and fruits" },
  { name: "Meat & Seafood", description: "Fresh and frozen meat, poultry, and seafood" },
  { name: "Bakery", description: "Bread, pastries, and baked goods" },
  { name: "Beverages", description: "Drinks including water, juice, soda, and coffee" },
  { name: "Frozen", description: "Frozen foods and ice cream" },
  { name: "Pantry", description: "Canned goods, dry goods, pasta, rice, and cereals" },
  { name: "Snacks", description: "Chips, crackers, cookies, and other snacks" },
  { name: "Cleaning & Household", description: "Cleaning supplies and household items" },
  { name: "Personal Care", description: "Toiletries, hygiene, and beauty products" },
  { name: "Baby & Kids", description: "Baby food, diapers, and children's products" },
  { name: "Pet Supplies", description: "Food and supplies for pets" }
]

categories.each do |category_attrs|
  Category.find_or_create_by!(name: category_attrs[:name]) do |category|
    category.description = category_attrs[:description]
  end
end

puts "Created #{Category.count} categories"

# Unit Types
unit_types = [
  { name: "Piece", abbreviation: "pcs" },
  { name: "Kilogram", abbreviation: "kg" },
  { name: "Gram", abbreviation: "g" },
  { name: "Liter", abbreviation: "L" },
  { name: "Milliliter", abbreviation: "mL" },
  { name: "Carton", abbreviation: "ctn" },
  { name: "Bottle", abbreviation: "btl" },
  { name: "Can", abbreviation: "can" },
  { name: "Bag", abbreviation: "bag" },
  { name: "Box", abbreviation: "box" },
  { name: "Pack", abbreviation: "pk" },
  { name: "Dozen", abbreviation: "dz" }
]

unit_types.each do |unit_type_attrs|
  UnitType.find_or_create_by!(name: unit_type_attrs[:name]) do |unit_type|
    unit_type.abbreviation = unit_type_attrs[:abbreviation]
  end
end

puts "Created #{UnitType.count} unit types"

# Default Items
items_by_category = {
  "Dairy" => [
    { name: "Milk", default_unit: "Carton" },
    { name: "Eggs", default_unit: "Dozen" },
    { name: "Butter", default_unit: "Pack" },
    { name: "Cheese", default_unit: "Pack" },
    { name: "Yogurt", default_unit: "Pack" },
    { name: "Cream", default_unit: "Carton" },
    { name: "Sour Cream", default_unit: "Pack" }
  ],
  "Produce" => [
    { name: "Potatoes", default_unit: "Kilogram" },
    { name: "Tomatoes", default_unit: "Kilogram" },
    { name: "Onions", default_unit: "Kilogram" },
    { name: "Garlic", default_unit: "Piece" },
    { name: "Carrots", default_unit: "Kilogram" },
    { name: "Lettuce", default_unit: "Piece" },
    { name: "Cucumbers", default_unit: "Piece" },
    { name: "Bell Peppers", default_unit: "Piece" },
    { name: "Apples", default_unit: "Kilogram" },
    { name: "Bananas", default_unit: "Kilogram" },
    { name: "Oranges", default_unit: "Kilogram" },
    { name: "Lemons", default_unit: "Piece" },
    { name: "Avocados", default_unit: "Piece" },
    { name: "Spinach", default_unit: "Bag" },
    { name: "Broccoli", default_unit: "Piece" }
  ],
  "Meat & Seafood" => [
    { name: "Chicken Breast", default_unit: "Kilogram" },
    { name: "Ground Beef", default_unit: "Kilogram" },
    { name: "Pork Chops", default_unit: "Kilogram" },
    { name: "Salmon", default_unit: "Kilogram" },
    { name: "Shrimp", default_unit: "Kilogram" },
    { name: "Bacon", default_unit: "Pack" },
    { name: "Sausages", default_unit: "Pack" }
  ],
  "Bakery" => [
    { name: "Bread", default_unit: "Piece" },
    { name: "Bagels", default_unit: "Pack" },
    { name: "Tortillas", default_unit: "Pack" },
    { name: "Croissants", default_unit: "Pack" },
    { name: "Muffins", default_unit: "Pack" }
  ],
  "Beverages" => [
    { name: "Water", default_unit: "Bottle" },
    { name: "Orange Juice", default_unit: "Carton" },
    { name: "Apple Juice", default_unit: "Carton" },
    { name: "Coffee", default_unit: "Bag" },
    { name: "Tea", default_unit: "Box" },
    { name: "Soda", default_unit: "Bottle" }
  ],
  "Frozen" => [
    { name: "Ice Cream", default_unit: "Pack" },
    { name: "Frozen Vegetables", default_unit: "Bag" },
    { name: "Frozen Pizza", default_unit: "Box" },
    { name: "Frozen Berries", default_unit: "Bag" }
  ],
  "Pantry" => [
    { name: "Rice", default_unit: "Bag" },
    { name: "Pasta", default_unit: "Box" },
    { name: "Canned Tomatoes", default_unit: "Can" },
    { name: "Canned Beans", default_unit: "Can" },
    { name: "Olive Oil", default_unit: "Bottle" },
    { name: "Vegetable Oil", default_unit: "Bottle" },
    { name: "Salt", default_unit: "Pack" },
    { name: "Pepper", default_unit: "Pack" },
    { name: "Sugar", default_unit: "Bag" },
    { name: "Flour", default_unit: "Bag" },
    { name: "Cereal", default_unit: "Box" },
    { name: "Oatmeal", default_unit: "Box" },
    { name: "Peanut Butter", default_unit: "Bottle" },
    { name: "Honey", default_unit: "Bottle" }
  ],
  "Snacks" => [
    { name: "Chips", default_unit: "Bag" },
    { name: "Crackers", default_unit: "Box" },
    { name: "Cookies", default_unit: "Pack" },
    { name: "Nuts", default_unit: "Bag" },
    { name: "Granola Bars", default_unit: "Box" },
    { name: "Popcorn", default_unit: "Bag" }
  ],
  "Cleaning & Household" => [
    { name: "Dish Soap", default_unit: "Bottle" },
    { name: "Laundry Detergent", default_unit: "Bottle" },
    { name: "Paper Towels", default_unit: "Pack" },
    { name: "Toilet Paper", default_unit: "Pack" },
    { name: "Trash Bags", default_unit: "Box" },
    { name: "All-Purpose Cleaner", default_unit: "Bottle" },
    { name: "Sponges", default_unit: "Pack" }
  ],
  "Personal Care" => [
    { name: "Shampoo", default_unit: "Bottle" },
    { name: "Conditioner", default_unit: "Bottle" },
    { name: "Body Wash", default_unit: "Bottle" },
    { name: "Toothpaste", default_unit: "Pack" },
    { name: "Deodorant", default_unit: "Piece" },
    { name: "Soap", default_unit: "Pack" }
  ],
  "Baby & Kids" => [
    { name: "Diapers", default_unit: "Pack" },
    { name: "Baby Wipes", default_unit: "Pack" },
    { name: "Baby Formula", default_unit: "Can" },
    { name: "Baby Food", default_unit: "Pack" }
  ],
  "Pet Supplies" => [
    { name: "Dog Food", default_unit: "Bag" },
    { name: "Cat Food", default_unit: "Bag" },
    { name: "Cat Litter", default_unit: "Bag" },
    { name: "Pet Treats", default_unit: "Bag" }
  ]
}

items_by_category.each do |category_name, items|
  category = Category.find_by!(name: category_name)

  items.each do |item_attrs|
    unit_type = UnitType.find_by(name: item_attrs[:default_unit])

    Item.find_or_create_by!(name: item_attrs[:name], category: category) do |item|
      item.default_unit_type = unit_type
      item.is_default = true
    end
  end
end

puts "Created #{Item.count} items"
