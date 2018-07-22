class AddPaysafecardToWalletHistories < ActiveRecord::Migration
  def change
    add_column :wallet_histories, :paysafecard, :string
  end
end
