class CreateWalletHistories < ActiveRecord::Migration
  def change
    create_table :wallet_histories do |t|
      t.integer :amount, default: 0
      t.string :action
      t.string :category
      t.references :wallet, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
