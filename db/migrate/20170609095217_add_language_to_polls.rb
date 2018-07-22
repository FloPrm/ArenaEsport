class AddLanguageToPolls < ActiveRecord::Migration[5.0]
  def change
    add_column :polls, :language, :string
  end
end
