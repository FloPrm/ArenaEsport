class AddTeamIdToMentorats < ActiveRecord::Migration[5.0]
  def change
    add_reference :mentorats, :team, foreign_key: true
  end
end
