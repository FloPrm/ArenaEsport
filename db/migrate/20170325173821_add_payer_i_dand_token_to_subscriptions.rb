class AddPayerIDandTokenToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :token, :string
    add_column :subscriptions, :payer_id, :string
  end
end
