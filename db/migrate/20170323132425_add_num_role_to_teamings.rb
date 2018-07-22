class AddNumRoleToTeamings < ActiveRecord::Migration
  def change
    add_column :teamings, :num_role, :integer
  end
end
