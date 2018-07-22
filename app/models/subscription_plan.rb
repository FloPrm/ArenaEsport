class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions
  has_many :users, through: :subscriptions

  DURATION = {"t 'subscriptions.lifetime'" => nil, "t 'subscriptions.one_month'" => 1}.freeze
end
