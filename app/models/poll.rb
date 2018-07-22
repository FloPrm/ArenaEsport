class Poll < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :pollings, dependent: :destroy
  has_many :voters, through: :pollings, :class_name => "User", source: :user

  self.per_page = 10

  validates :title, presence: true, length: { maximum: 50 }
  validates :body, length: { maximum: 2000 }
  # validate :validate_choices, on: :update

  def validate_choices
    errors.add(:choices, "Il n'y a pas assez de choix de vote.") if choices.size < 2
  end
end
