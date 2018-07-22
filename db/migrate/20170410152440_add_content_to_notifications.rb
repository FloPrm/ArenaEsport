class AddContentToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :content, :string
  end
end
