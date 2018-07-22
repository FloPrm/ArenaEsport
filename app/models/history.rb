class History < ApplicationRecord
  belongs_to :team
  belongs_to :teaming
  belongs_to :user

  ACTIONS = {"Tournoi" => "tournament", "Match amical" => "scrim", "Autre" => "autre"}.freeze

  validates :action, length: { maximum: 30 }
  validates :content, length: { maximum: 250 }

end
