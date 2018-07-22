class Game < ApplicationRecord
	has_many :game_accounts
	has_many :teams
	has_many :tournaments
	has_many :champions
	has_many :polls
end
