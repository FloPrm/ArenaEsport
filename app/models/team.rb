class Team < ApplicationRecord
	attr_accessor :language

	has_many :teamings, dependent: :destroy
	has_many :users, through: :teamings
	has_many :members,
								-> { where teamings: { active: true } },
								through: :teamings,
								source: :user

	has_many :accounts,
								-> { where game_accounts: { active: true } },
								through: :members,
								source: :game_accounts

	has_many :friendships, through: :members
	has_many :blacklisted,
                  -> { where friendships: { status: 3 } },
                  through: :friendships,
                  source: :friend

	has_many :plannings, dependent: :destroy
	has_many :votes, dependent: :destroy
	has_many :invitations, dependent: :destroy
	has_many :team_applications, dependent: :destroy
	has_many :candidates, through: :team_applications, source: :user

	has_many :notifiables,
										-> { where notifications: { notifiable_id: self, notifiable_type: "Team" } },
										through: :users,
										source: :notifications,
										dependent: :destroy

	belongs_to :game

	has_many :histories, dependent: :destroy

	has_one :chat_room, dependent: :destroy
	has_many :messages, dependent: :destroy

	has_many :compositions, dependent: :destroy
	has_many :notes, dependent: :destroy

	has_one :mentorat, dependent: :destroy
	has_one :mentor, through: :mentorat
  has_many :seances, through: :mentorat, dependent: :destroy

	validates :name, length: { maximum: 30 }

	def language
		self.members.pluck(:lang_p).group_by(&:to_s).values.max_by(&:size).try(:first)
	end

end
