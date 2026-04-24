class DropUserPrograms < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_programs
  end
end
