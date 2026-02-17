namespace :recurring_lists do
  desc "Process all recurring shopping lists that are due"
  task process: :environment do
    Rails.logger.info("Starting recurring lists processing...")
    RecurringListJob.perform_now
    Rails.logger.info("Recurring lists processing completed.")
  end
end
