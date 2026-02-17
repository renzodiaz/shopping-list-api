module Api::V1
  class NotificationsController < BaseController
    before_action :set_notification, only: %i[show mark_as_read]

    def index
      notifications = current_user.notifications.recent
      notifications = apply_filters(notifications)
      serialize(notifications, serializer: NotificationSerializer)
    end

    def show
      serialize(@notification, serializer: NotificationSerializer)
    end

    def mark_as_read
      @notification.mark_as_read!
      serialize(@notification, serializer: NotificationSerializer)
    end

    def mark_all_as_read
      current_user.notifications.unread.update_all(read_at: Time.current)
      head :no_content
    end

    def unread_count
      count = current_user.notifications.unread.count
      render json: { data: { unread_count: count } }
    end

    private

    def set_notification
      @notification = current_user.notifications.find(params[:id])
    end

    def apply_filters(notifications)
      notifications = notifications.unread if params[:unread] == "true"
      notifications = notifications.read if params[:read] == "true"
      notifications = notifications.where(notification_type: params[:type]) if params[:type].present?
      notifications = notifications.limit(params[:limit].to_i) if params[:limit].present?
      notifications
    end
  end
end
