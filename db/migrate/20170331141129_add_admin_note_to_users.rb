class AddAdminNoteToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin_note, :text
  end
end
