class AddDiscordToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :discord, :string
  end
end
