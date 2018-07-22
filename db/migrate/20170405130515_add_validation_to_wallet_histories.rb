class AddValidationToWalletHistories < ActiveRecord::Migration
  def change
    add_column :wallet_histories, :validation, :boolean
  end
end
