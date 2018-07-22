class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  #nom de l'attribut pour l'image de profil
  mount_uploader :avatar, AvatarUploader
  geocoded_by :address
  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }
  delegate :can?, :cannot?, :to => :ability

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  #Subs could posisbly have many teams, and this helps aswell if new games are added + historique
  has_many :teamings, dependent: :destroy
  has_one :teaming, -> { where teamings: { active: true } }, :class_name => "Teaming"
  has_many :teams, through: :teamings
  has_one :team, -> { where teamings: { active: true } }, through: :teaming, source: :team
  has_many :team_applications, dependent: :destroy
  has_many :votes, :class_name => "Vote", foreign_key: :votable_id
  has_many :elections, -> { where votes: { result: true } }, :class_name => "Vote", foreign_key: :votable_id

  has_many :plannings, dependent: :destroy

  has_many :game_accounts, dependent: :destroy
  has_one :account, -> { where game_accounts: { active: true } }, :class_name => "GameAccount"
  has_one :game, through: :account

  has_many :filleuls, :class_name => "User", foreign_key: :parrain

  has_many :articles, dependent: :destroy

  has_many :notifications, foreign_key: :recepteur_id, dependent: :destroy
  has_many :sended_notifications, :class_name => "Notification", foreign_key: :emetteur_id, dependent: :destroy

  has_many :invitations, foreign_key: :sender_id, dependent: :destroy
  has_many :pending_invitations, :class_name => "Invitation", foreign_key: :receiver_id, dependent: :destroy

  has_many :friendships, dependent: :destroy
  has_many :reverse_friendships, :class_name => "Friendship", foreign_key: :friend_id, dependent: :destroy

  has_many :pending_friends,
                  -> { where friendships: { status: 0 } },
                  through: :friendships,
                  source: :friend

  has_many :requested_friends,
                  -> { where friendships: { status: 1 } },
                  through: :friendships,
                  source: :friend

  has_many :friends,
                  -> { where friendships: { status: 2 } },
                  through: :friendships

  has_many :blocked_friends,
                  -> { where friendships: { status: 3 } },
                  through: :friendships,
                  source: :friend

  has_many :friends_accounts, :class_name => "GameAccount", through: :friends, source: :game_accounts

  has_one :mentor, through: :account
  has_one :mentorat, through: :account
  has_many :seances, through: :mentorat
  has_many :feedbacks, dependent: :destroy

  has_many :histories, dependent: :destroy

  has_many :achievables, dependent: :destroy
  has_many :achievements, through: :achievables
  has_many :badges, through: :achievements

  has_one :wallet, dependent: :destroy

  has_many :subscriptions, dependent: :destroy
  has_one :active_subscription, -> { where subscriptions: { active: true } }, :class_name => "Subscription"

  has_many :messages, dependent: :destroy
  has_many :team_messages, through: :team, source: :messages

  has_many :notes, dependent: :destroy

  has_many :polls, dependent: :destroy
  has_many :pollings, dependent: :destroy

  has_many :given_karmas, :class_name => "Karma", foreign_key: :voter_id
  has_many :received_karmas, :class_name => "Karma", foreign_key: :voted_id

  has_many :urls

  self.per_page = 20

  #validates :birth_date, :presence => true, :on => :update
  validates_inclusion_of :birth_date,
    :in => Date.new(1960)..Time.now.years_ago(12).to_date,
    :message => ": Tu es trop jeune pour pouvoir t'inscrire!"

  before_validation :format_discord

  validates :user_name, length: { maximum: 30 }, uniqueness: true
  validates :email, length: { maximum: 50 }
  validates :first_name, length: { maximum: 30 }
  validates :last_name, length: { maximum: 30 }
  validates :address, length: { maximum: 100 }

  validates :horaire, length: { maximum: 250 }
  validates :skype, length: { maximum: 50 }
  validates :discord, length: { maximum: 50 }

  validates :week_start, presence: true, numericality: true
  validates :week_end, presence: true, numericality: true
  validates :we_start, presence: true, numericality: true
  validates :we_end, presence: true, numericality: true

  #mieux vaut stocker des entiers que des chaines de caractères
  #mais plus lisible de faire user.teamless?
  scope :teamless, -> { where(state: "0") }
  scope :searching, -> { where(state: "1") }
  scope :teamed, -> { where(state: "2") }

  before_create :generate_wallet

  #différents rôles à sélectionner
  ROLES = %w[admin moderator standard arena_p captain_p banned].freeze

  START = {"1" => 1,
          "2" => 2
          }.freeze

  JOUR = {"Absent" => 0, "09H" => 9, "10H" => 10, "11H" => 11, "12H" => 12, "13H" => 13, "14H" => 14,
          "15H" => 15, "16H" => 16, "17H" => 17, "18H" => 18, "19H" => 19, "20H" => 20, "21H" => 21, "22H" => 22}.freeze

  SOIR = {"Absent" => 0, "16H" => 16, "17H" => 17, "18H" => 18, "19H" => 19, "20H" => 20, "21H" => 21, "22H" => 22,
          "23H" => 23, "00H" => 24, "01H" => 25, "02H" => 26, "03H" => 27, "04H" => 28}.freeze

  LANGUAGES = {"t 'language.french'" => "french", "t 'language.english'" => "english"}.freeze

  def premade
    Premade.where("user1 = ? OR user2 = ? OR user3 = ?", self.account, self.account, self.account).first
  end


  def premades
    ([self.premade.user1] + [self.premade.user2] + [self.premade.user3] - [self.account]).reject(&:nil?)
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
		where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    	user.email = auth.info.email
	    user.password = Devise.friendly_token[0,20]
  	  user.user_name = auth.info.name   # assuming the user model has a name
    	user.first_name = auth.extra.raw_info.first_name
	    user.last_name = auth.extra.raw_info.last_name
  	  #user.image = auth.info.image # assuming the user model has an image
  	end
  end

  def generate_wallet
    self.build_wallet
  end

  def format_discord
    self.discord = (discord.split('#').first.strip + "#" + discord.split('#').last.strip).to_s if discord.present?
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def country_name
    country = ISO3166::Country[self.country]
    country.translations[I18n.locale.to_s] || country.name
  end

end
