class NotificationService
  class << self
    def notify_low_stock(inventory_item, exclude_user: nil)
      household = inventory_item.household
      title = "Low Stock Alert"
      body = "#{inventory_item.display_name} is running low (#{inventory_item.quantity} remaining)"

      notify_household_members(
        household: household,
        notification_type: "low_stock",
        title: title,
        body: body,
        notifiable: inventory_item,
        exclude_user: exclude_user
      )

      # Send push notifications
      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "low_stock", inventory_item_id: inventory_item.id },
        exclude_user: exclude_user
      )

      # Send emails to household members
      send_emails_to_household(household, exclude_user: exclude_user) do |user|
        NotificationMailer.low_stock_alert(user, inventory_item)
      end
    end

    def notify_out_of_stock(inventory_item, exclude_user: nil)
      household = inventory_item.household
      title = "Out of Stock"
      body = "#{inventory_item.display_name} is out of stock"

      notify_household_members(
        household: household,
        notification_type: "out_of_stock",
        title: title,
        body: body,
        notifiable: inventory_item,
        exclude_user: exclude_user
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "out_of_stock", inventory_item_id: inventory_item.id },
        exclude_user: exclude_user
      )

      send_emails_to_household(household, exclude_user: exclude_user) do |user|
        NotificationMailer.out_of_stock_alert(user, inventory_item)
      end
    end

    def notify_list_completed(shopping_list, completed_by:)
      household = shopping_list.household
      title = "Shopping List Completed"
      body = "#{shopping_list.name} has been marked as completed by #{completed_by.email}"

      notify_household_members(
        household: household,
        notification_type: "list_completed",
        title: title,
        body: body,
        notifiable: shopping_list,
        exclude_user: completed_by
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "list_completed", shopping_list_id: shopping_list.id },
        exclude_user: completed_by
      )

      send_emails_to_household(household, exclude_user: completed_by) do |user|
        NotificationMailer.list_completed(user, shopping_list, completed_by)
      end
    end

    def notify_item_checked(shopping_list_item, checked_by:)
      household = shopping_list_item.shopping_list.household
      title = "Item Checked"
      body = "#{shopping_list_item.display_name} was checked off from #{shopping_list_item.shopping_list.name}"

      notify_household_members(
        household: household,
        notification_type: "item_checked",
        title: title,
        body: body,
        notifiable: shopping_list_item,
        exclude_user: checked_by
      )

      # Push notification only (no email for individual item checks)
      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "item_checked", shopping_list_item_id: shopping_list_item.id },
        exclude_user: checked_by
      )
    end

    def notify_invitation_received(invitation)
      return unless invitation.email.present?

      user = User.find_by(email: invitation.email)

      # Create in-app notification if user exists
      if user
        Notification.create!(
          user: user,
          notification_type: "invitation_received",
          title: "Household Invitation",
          body: "You've been invited to join #{invitation.household.name}",
          notifiable: invitation
        )

        PushNotificationService.send_to_user(
          user,
          title: "Household Invitation",
          body: "You've been invited to join #{invitation.household.name}",
          data: { type: "invitation_received", invitation_token: invitation.token }
        )
      end

      # Always send email (even if user doesn't exist yet)
      NotificationMailer.invitation_received(invitation).deliver_later
    end

    def notify_invitation_accepted(invitation, accepted_by:)
      household = invitation.household
      title = "Invitation Accepted"
      body = "#{accepted_by.email} has joined #{household.name}"

      notify_household_members(
        household: household,
        notification_type: "invitation_accepted",
        title: title,
        body: body,
        notifiable: invitation,
        exclude_user: accepted_by
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "invitation_accepted", user_email: accepted_by.email },
        exclude_user: accepted_by
      )
    end

    def notify_member_joined(household, new_member)
      title = "New Member"
      body = "#{new_member.email} has joined #{household.name}"

      notify_household_members(
        household: household,
        notification_type: "member_joined",
        title: title,
        body: body,
        notifiable: household,
        exclude_user: new_member
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "member_joined", user_email: new_member.email },
        exclude_user: new_member
      )
    end

    def notify_member_left(household, member_who_left)
      title = "Member Left"
      body = "#{member_who_left.email} has left #{household.name}"

      notify_household_members(
        household: household,
        notification_type: "member_left",
        title: title,
        body: body,
        notifiable: household
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "member_left", user_email: member_who_left.email }
      )
    end

    def notify_recurring_list_created(shopping_list)
      household = shopping_list.household
      title = "Recurring List Created"
      body = "#{shopping_list.name} has been automatically created from your recurring list"

      notify_household_members(
        household: household,
        notification_type: "recurring_list_created",
        title: title,
        body: body,
        notifiable: shopping_list
      )

      PushNotificationService.send_to_household(
        household,
        title: title,
        body: body,
        data: { type: "recurring_list_created", shopping_list_id: shopping_list.id }
      )

      send_emails_to_household(household) do |user|
        NotificationMailer.recurring_list_created(user, shopping_list)
      end
    end

    private

    def notify_household_members(household:, notification_type:, title:, body:, notifiable: nil, exclude_user: nil)
      members = household.members
      members = members.where.not(id: exclude_user.id) if exclude_user

      notifications = members.map do |user|
        {
          user_id: user.id,
          notification_type: notification_type,
          title: title,
          body: body,
          notifiable_type: notifiable&.class&.name,
          notifiable_id: notifiable&.id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      Notification.insert_all(notifications) if notifications.any?
    end

    def send_emails_to_household(household, exclude_user: nil)
      members = household.members
      members = members.where.not(id: exclude_user.id) if exclude_user

      members.find_each do |user|
        yield(user).deliver_later
      end
    end
  end
end
