class Notification < ApplicationRecord
  belongs_to :emetteur, class_name: "User"
  belongs_to :recepteur, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

  after_create_commit {NotificationBroadcastJob.perform_later self}
end
