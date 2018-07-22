class AddCharactersToGames < ActiveRecord::Migration[5.0]
  def change
    add_column :games, :characters, :boolean, default: false
  end
end
