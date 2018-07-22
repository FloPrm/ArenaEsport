class CreateKarmas < ActiveRecord::Migration[5.0]
  def change
    create_table :karmas do |t|
      t.integer :voter_id
      t.integer :voted_id
      t.integer :vote
      t.text :comment

      t.timestamps
    end
  end
end
