FactoryBot.define do
  factory :notification do
    user
    notification_type { "low_stock" }
    title { "Notification Title" }
    body { "Notification body text" }
    read_at { nil }
    notifiable { nil }

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :low_stock do
      notification_type { "low_stock" }
      title { "Low Stock Alert" }
      body { "An item is running low in your inventory" }
    end

    trait :out_of_stock do
      notification_type { "out_of_stock" }
      title { "Out of Stock Alert" }
      body { "An item is out of stock in your inventory" }
    end

    trait :list_completed do
      notification_type { "list_completed" }
      title { "Shopping List Completed" }
      body { "A shopping list has been completed" }
    end

    trait :invitation_received do
      notification_type { "invitation_received" }
      title { "New Invitation" }
      body { "You have received an invitation to join a household" }
    end

    trait :with_inventory_item do
      association :notifiable, factory: :inventory_item
    end

    trait :with_shopping_list do
      association :notifiable, factory: :shopping_list
    end

    trait :with_invitation do
      association :notifiable, factory: :invitation
    end
  end
end
