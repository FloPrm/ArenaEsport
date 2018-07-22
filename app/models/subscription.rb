class Subscription < ApplicationRecord
  belongs_to :user
  has_one :account, through: :user, :class_name => "GameAccount"
  belongs_to :subscription_plan

  DURATION = {"1 mois" => 1, "3 mois (-5%)" => 3, "6 mois (-10%)" => 6, "12 mois (2 mois gratuits)" => 12}.freeze

  self.per_page = 20
end
