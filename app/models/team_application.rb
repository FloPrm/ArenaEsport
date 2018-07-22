class TeamApplication < ApplicationRecord
  belongs_to :user
  belongs_to :team

  self.per_page = 20

  validates :role, length: { maximum: 30 }
  validates :content, length: { maximum: 1100 }
end
