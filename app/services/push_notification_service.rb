class PushNotificationService
  class << self
    def send_to_user(user, title:, body:, data: {})
      device_tokens = user.device_tokens

      device_tokens.find_each do |device_token|
        send_to_device(device_token, title: title, body: body, data: data)
      end
    end

    def send_to_users(users, title:, body:, data: {})
      users.each do |user|
        send_to_user(user, title: title, body: body, data: data)
      end
    end

    def send_to_household(household, title:, body:, data: {}, exclude_user: nil)
      users = household.members
      users = users.where.not(id: exclude_user.id) if exclude_user

      send_to_users(users, title: title, body: body, data: data)
    end

    private

    def send_to_device(device_token, title:, body:, data: {})
      case device_token.platform
      when "ios"
        send_apns(device_token, title: title, body: body, data: data)
      when "android"
        send_fcm(device_token, title: title, body: body, data: data)
      when "web"
        send_web_push(device_token, title: title, body: body, data: data)
      end
    rescue StandardError => e
      Rails.logger.error("Push notification failed for device #{device_token.id}: #{e.message}")
      handle_invalid_token(device_token, e)
    end

    def send_apns(device_token, title:, body:, data:)
      # TODO: Implement APNS push notification
      # This would use a gem like 'apnotic' or 'houston'
      #
      # Example with apnotic:
      # connection = Apnotic::Connection.new(cert_path: ENV['APNS_CERT_PATH'])
      # notification = Apnotic::Notification.new(device_token.token)
      # notification.alert = { title: title, body: body }
      # notification.custom_payload = data
      # connection.push(notification)

      Rails.logger.info("[APNS] Sending to #{device_token.token[0..10]}...: #{title}")
    end

    def send_fcm(device_token, title:, body:, data:)
      # TODO: Implement FCM push notification
      # This would use a gem like 'fcm' or 'googleauth'
      #
      # Example with fcm gem:
      # fcm = FCM.new(ENV['FCM_SERVER_KEY'])
      # response = fcm.send(
      #   [device_token.token],
      #   notification: { title: title, body: body },
      #   data: data
      # )

      Rails.logger.info("[FCM] Sending to #{device_token.token[0..10]}...: #{title}")
    end

    def send_web_push(device_token, title:, body:, data:)
      # TODO: Implement Web Push notification
      # This would use a gem like 'web-push'
      #
      # Example with web-push gem:
      # WebPush.payload_send(
      #   message: { title: title, body: body, data: data }.to_json,
      #   endpoint: device_token.token,
      #   p256dh: device_token.p256dh,
      #   auth: device_token.auth,
      #   vapid: { ... }
      # )

      Rails.logger.info("[WebPush] Sending to #{device_token.token[0..10]}...: #{title}")
    end

    def handle_invalid_token(device_token, error)
      # Handle invalid/expired tokens by removing them
      # This would be platform-specific based on error responses
      if invalid_token_error?(error)
        device_token.destroy
        Rails.logger.info("Removed invalid device token #{device_token.id}")
      end
    end

    def invalid_token_error?(error)
      # Check if the error indicates an invalid token
      # This would be platform-specific
      error.message.include?("InvalidToken") ||
        error.message.include?("NotRegistered") ||
        error.message.include?("Unregistered")
    end
  end
end
