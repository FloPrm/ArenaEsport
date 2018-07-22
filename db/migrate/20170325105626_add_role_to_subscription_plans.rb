class AddRoleToSubscriptionPlans < ActiveRecord::Migration
  def change
    add_column :subscription_plans, :role, :string
  end
end
