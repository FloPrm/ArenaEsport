class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    ActionCable.server.broadcast "notification_#{notification.recepteur_id}", notification: render_notification(notification), unread: notification.recepteur.notifications.unread.count
  end

  private
    def render_notification(notification)
      ApplicationController.renderer.render(partial: 'notifications/notification', locals: { notification: notification })
    end
end
