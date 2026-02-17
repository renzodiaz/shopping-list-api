class NotificationSerializer
  include JSONAPI::Serializer

  attributes :notification_type, :title, :body, :read_at, :created_at

  attribute :read do |notification|
    notification.read?
  end

  attribute :notifiable_type do |notification|
    notification.notifiable_type&.underscore
  end

  attribute :notifiable_id do |notification|
    notification.notifiable_id
  end
end
