class NotificationMailer < ApplicationMailer
  def low_stock_alert(user, inventory_item)
    @user = user
    @inventory_item = inventory_item
    @household = inventory_item.household

    mail(
      to: user.email,
      subject: "Low Stock Alert: #{inventory_item.display_name}"
    )
  end

  def out_of_stock_alert(user, inventory_item)
    @user = user
    @inventory_item = inventory_item
    @household = inventory_item.household

    mail(
      to: user.email,
      subject: "Out of Stock: #{inventory_item.display_name}"
    )
  end

  def list_completed(user, shopping_list, completed_by)
    @user = user
    @shopping_list = shopping_list
    @completed_by = completed_by
    @household = shopping_list.household

    mail(
      to: user.email,
      subject: "Shopping List Completed: #{shopping_list.name}"
    )
  end

  def invitation_received(invitation)
    @invitation = invitation
    @household = invitation.household
    @invited_by = invitation.invited_by

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@household.name}"
    )
  end

  def recurring_list_created(user, shopping_list)
    @user = user
    @shopping_list = shopping_list
    @household = shopping_list.household

    mail(
      to: user.email,
      subject: "Recurring List Created: #{shopping_list.name}"
    )
  end
end
