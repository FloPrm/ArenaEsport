# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "appearance_channel"
    ActionCable.server.broadcast "appearance_channel", user_id: current_user.id, online: true
    current_user.update_attribute(:status, 1)
  end

  def unsubscribed
    ActionCable.server.broadcast "appearance_channel", user_id: current_user.id, online: false, offline: render_offline
    current_user.update_attribute(:status, 0)
  end

  private
    def render_offline
      ApplicationController.renderer.render(partial: 'friendships/last_sign_in', locals: { date: Time.now.in_time_zone('Europe/Paris')})
    end

end
