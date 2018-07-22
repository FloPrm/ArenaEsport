class CreateCompositions < ActiveRecord::Migration[5.0]
  def change
    create_table :compositions do |t|
      t.references :team, foreign_key: true
      t.string :picks, array: true, default: []
      t.string :bans, array: true, default: []
      t.integer :win, default: 0
      t.integer :lose, default: 0

      t.timestamps
    end
  end
end
