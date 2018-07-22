class AddDiscordEuToGames < ActiveRecord::Migration[5.0]
  def change
    add_column :games, :discord_eu, :string
  end
end
