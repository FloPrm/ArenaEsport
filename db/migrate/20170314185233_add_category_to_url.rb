class AddCategoryToUrl < ActiveRecord::Migration
  def change
  	add_column :shortened_urls, :category, :string
  end
end
