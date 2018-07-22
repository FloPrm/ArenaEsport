class AddTitleToCompositions < ActiveRecord::Migration[5.0]
  def change
    add_column :compositions, :title, :string
  end
end
