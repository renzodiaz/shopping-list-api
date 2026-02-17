class RecurringListJob < ApplicationJob
  queue_as :default

  def perform
    ShoppingList.due_for_recurrence.find_each do |shopping_list|
      process_recurring_list(shopping_list)
    end
  end

  private

  def process_recurring_list(shopping_list)
    shopping_list.create_recurring_instance!
    Rails.logger.info("Created recurring instance for ShoppingList ##{shopping_list.id}")
  rescue StandardError => e
    Rails.logger.error("Failed to create recurring instance for ShoppingList ##{shopping_list.id}: #{e.message}")
    # Re-raise to let the job framework handle retries
    raise
  end
end
