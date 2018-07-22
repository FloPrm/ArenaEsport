class AddNumRoleToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :num_role, :integer
  end
end
