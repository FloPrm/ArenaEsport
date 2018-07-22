class Teaming < ApplicationRecord
  belongs_to :team
  belongs_to :user
  has_one :account, -> { where game_accounts: { active: true } }, through: :user, source: :game_accounts

  has_many :histories, dependent: :destroy

  self.per_page = 20

  LEAVE = {
          "t 'teams.leave1'" => 1,
          "t 'teams.leave2'" => 2,
          "t 'teams.leave3'" => 3,
          "t 'teams.leave4'" => 4,
          "t 'teams.leave5'" => 5,
          "t 'teams.leave6'" => 6,
          "t 'teams.leave7'" => 7
          }.freeze

  ransacker :created_at, type: :date do
    Arel.sql('date(created_at)')
  end
end
