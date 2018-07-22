class Achievement < ApplicationRecord
  has_one :badge
  has_many :achievables
  has_many :users, through: :achievables

  self.per_page = 30

  CATEGORY = %w[users game_accounts teams teamings histories votes friendships mentors mentorats seances feedbacks].freeze

  validates :name, length: { maximum: 30 }
  validates :category, length: { maximum: 50 }
  validates :description, length: { maximum: 250 }
  validates :condition, length: { maximum: 150 }

end
