class Tournament < ApplicationRecord
  belongs_to :game

  DAYS = {"t 'layout.mon'" => 1, "t 'layout.tue'" => 2, "t 'layout.wed'" => 3, "t 'layout.thu'" => 4, "t 'layout.fri'" => 5, "t 'layout.sat'" => 6, "t 'layout.sun'" => 7}.freeze

  FREQUENCY = {"t 'tournaments.frequency1'" => 1, "t 'tournaments.frequency2'" => 2, "t 'tournaments.frequency3'" => 3, "t 'tournaments.frequency4'" => 4}.freeze

  MMR = {"Aucun lol" => 3000, "Platinum lol" => 1760, "Gold lol" => 1560, "Aucun ow" => 5000}.freeze

  MAPS = {"Summoners Rift" => 1, "Twisted Treeline" => 2, "Howling Abyss" => 3, "Maps aléatoires" => 4}.freeze

  BATTLE = {"5v5" => 1, "3v3" => 2, "1v1" => 3, "6v6" => 4}.freeze

end
