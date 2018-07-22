class AddUnsubscribeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unsubscribe, :boolean
  end
end
