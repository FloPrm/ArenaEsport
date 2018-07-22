class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = Notification.where(recepteur: current_user)
  end

  def mark_as_read
    @notifications = Notification.where(recepteur:current_user).unread
    @notifications.each do |notification|
      notification.read_at = Time.now.to_s
      notification.save
    end

    respond_to do |format|
      format.js
    end
  end

  def mark_read
    @notification = Notification.find(params[:id])
    @notification.read_at = Time.now.to_s
    @notification.save
    if @notification.category == "mentorat" && @notification.action == "demande-team"
    redirect_to mentorats_path
    elsif !@notification.notifiable.nil?
      redirect_to @notification.notifiable
    elsif @notification.category == "team_application"
      redirect_to recruitment_center_path
    else
      redirect_to dashboard_path
    end
  end

end
