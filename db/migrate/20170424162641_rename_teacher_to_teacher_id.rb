class RenameTeacherToTeacherId < ActiveRecord::Migration[5.0]
  def change
    rename_column :mentorats, :teacher, :teacher_id
  end
end
