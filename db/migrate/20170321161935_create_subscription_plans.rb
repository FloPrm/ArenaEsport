class CreateSubscriptionPlans < ActiveRecord::Migration
  def change
    create_table :subscription_plans do |t|
      t.string :title
      t.text :content
      t.decimal :price

      t.timestamps null: false
    end
  end
end
