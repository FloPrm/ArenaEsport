class AddCompoBanToGames < ActiveRecord::Migration[5.0]
  def change
    add_column :games, :compo_bans, :boolean, default: false
  end
end
