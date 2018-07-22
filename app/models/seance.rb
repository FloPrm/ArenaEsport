class Seance < ApplicationRecord
  belongs_to :mentorat
  belongs_to :mentor

  DURATION = {"0H30" => 30, "1H" => 60, "1H30" => 90, "2H" => 120, "2H30" => 150, "3H" => 180, "3H30" => 210, "4H" => 240}.freeze

  validates :title, length: { maximum: 45 }
  validates :content, length: { maximum: 2500 }
  validates :advice, length: { maximum: 2500 }

end
