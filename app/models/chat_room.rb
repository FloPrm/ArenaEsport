class ChatRoom < ApplicationRecord
  belongs_to :team
  has_many :messages, dependent: :destroy
end
