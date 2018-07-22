class Note < ApplicationRecord
  belongs_to :user
  belongs_to :team
  belongs_to :composition
  
  self.per_page = 25

  validates :body, length: { maximum: 500 }, presence: true
end
