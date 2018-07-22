class AddSubscriptionPlanToSubscriptions < ActiveRecord::Migration
  def change
    add_reference :subscriptions, :subscription_plan, index: true, foreign_key: true
  end
end
