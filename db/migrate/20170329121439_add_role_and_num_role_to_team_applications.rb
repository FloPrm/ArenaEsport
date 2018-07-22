class AddRoleAndNumRoleToTeamApplications < ActiveRecord::Migration
  def change
    add_column :team_applications, :role, :string
    add_column :team_applications, :num_role, :integer
  end
end
