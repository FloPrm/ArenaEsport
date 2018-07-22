class AddDiscordToGames < ActiveRecord::Migration
  def change
    add_column :games, :discord, :string
  end
end
