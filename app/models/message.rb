class Message < ApplicationRecord
  belongs_to :chat_room
  belongs_to :team
  belongs_to :user
  has_one :account, through: :user, source: :account

  self.per_page = 100

  after_create_commit {MessageBroadcastJob.perform_later self}

  validates :body, length: { maximum: 500 }, presence: true
end
