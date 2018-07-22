class Composition < ApplicationRecord
  belongs_to :team
  has_many :notes

  self.per_page = 25
end
