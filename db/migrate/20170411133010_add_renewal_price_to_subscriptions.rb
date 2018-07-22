class AddRenewalPriceToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :renewal_price, :decimal
  end
end
