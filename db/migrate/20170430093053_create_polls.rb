class CreatePolls < ActiveRecord::Migration[5.0]
  def change
    create_table :polls do |t|
      t.references :user, foreign_key: true
      t.references :game, foreign_key: true
      t.string :title
      t.text :body
      t.string :choices, array: true, default: []
      t.boolean :featured, default: false
      t.integer :result, default: 0

      t.timestamps
    end
  end
end
