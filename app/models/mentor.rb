class Mentor < ApplicationRecord
  extend OrderAsSpecified
  belongs_to :game_account
  has_one :user, through: :game_account
  belongs_to :account, :class_name => "GameAccount", foreign_key: :game_account_id
  has_one :game, through: :game_account

  has_one :user, through: :game_account
  has_many :mentorats
  has_many :pending_mentorats, :class_name => "Mentorat", foreign_key: :teacher_id
  has_many :seances

  has_many :feedbacks, dependent: :destroy
  has_many :mentorats, through: :feedbacks

  self.per_page = 12

  SUIVI = {"t 'mentors.individual'" => "individuel", "t 'mentors.team'" => "equipe"}.freeze

  CERTIFICATION = {"t 'mentors.certified'" => 1, "t 'mentors.veteran'" => 2, "t 'mentors.legend'" => 3, "t 'mentors.god'" => 4}.freeze

  validates :suivi, presence: true
  validates :about, length: { maximum: 2200 }
  validates :cours, length: { maximum: 2200 }
end
