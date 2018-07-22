class CreatePollings < ActiveRecord::Migration[5.0]
  def change
    create_table :pollings do |t|
      t.references :user, foreign_key: true
      t.references :poll, foreign_key: true
      t.integer :vote

      t.timestamps
    end
  end
end
