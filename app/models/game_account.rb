class GameAccount < ApplicationRecord
	belongs_to :user
	belongs_to :game
	has_one :mentor, dependent: :destroy
	has_one :mentorat, dependent: :destroy
	has_one :premade

	#sert à la sélection dans le formulaire
	OBJECTIFS = { "t 'users.goal1'" => 1,
								"t 'users.goal2'" => 2,
								"t 'users.goal3'" => 3,
								"t 'users.goal4'" => 4
							}.freeze

	validates :name, length: { maximum: 50 }, presence: true, uniqueness: true, case_sensitive: false, on: :create
	#un compte doit avoir un rôle principal
	validates :p_role, presence: true, on: :update
	validates :autre, length: { maximum: 500 }, on: :update
	validate :validate_champions, on: :update

	def validate_champions
    errors.add(:champions, "Il y a trop de champions.") if champions.size > 3
  end

	def premade
    Premade.where("user1 = ? OR user2 = ? OR user3 = ?", self.id, self.id, self.id).first
  end
end
