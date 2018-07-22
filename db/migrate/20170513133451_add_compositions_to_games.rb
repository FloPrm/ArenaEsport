class AddCompositionsToGames < ActiveRecord::Migration[5.0]
  def change
    add_column :games, :compositions, :boolean, default: false
  end
end
