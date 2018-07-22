class AddLocalesToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :country, :string
    add_column :users, :lang_p, :string
    add_column :users, :lang_s, :string, array: true, default: []
  end
end
