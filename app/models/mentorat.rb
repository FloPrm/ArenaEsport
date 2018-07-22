class Mentorat < ApplicationRecord
  belongs_to :game_account
  belongs_to :account, :class_name => "GameAccount", foreign_key: :game_account_id
  belongs_to :team
  has_one :user, through: :game_account
  has_one :game, through: :game_account
  has_one :team_game, through: :team, :class_name => "Game"

  belongs_to :mentor
  belongs_to :teacher, :class_name => "Mentor", inverse_of: :pending_mentorats
  has_many :notifications, -> { where notifications: { notifiable_type: "Mentorat" } }, foreign_key: :notifiable_id, dependent: :destroy
  # belongs_to :teacher, class_name: "Mentor", foreign_key: :teacher
  has_many :seances, dependent: :destroy

  has_many :feedbacks, dependent: :destroy
  has_many :mentors, through: :feedbacks

  validates :hours, numericality: { less_than_or_equal_to: 100,  only_integer: true }
  validates :problem, length: { maximum: 2200 }
end
