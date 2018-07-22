class CreateChatRooms < ActiveRecord::Migration
  def change
    create_table :chat_rooms do |t|
      t.references :team, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
