class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true, foreign_key: true
      t.string :role
      t.boolean :active
      t.date :end_date
      t.decimal :price

      t.timestamps null: false
    end
  end
end
