class RemoveRoleFromSubscriptions < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :role
  end
end
