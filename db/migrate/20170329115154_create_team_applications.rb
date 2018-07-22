class CreateTeamApplications < ActiveRecord::Migration
  def change
    create_table :team_applications do |t|
      t.references :user, index: true, foreign_key: true
      t.references :team, index: true, foreign_key: true
      t.text :content

      t.timestamps null: false
    end
  end
end
