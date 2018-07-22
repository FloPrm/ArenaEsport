class AddAdvicesToTeamings < ActiveRecord::Migration[5.0]
  def change
    add_column :teamings, :advices, :boolean, default: false
  end
end
