class AddRenewalDurationToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :renewal_duration, :integer
  end
end
