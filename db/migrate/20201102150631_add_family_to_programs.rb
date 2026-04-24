class AddFamilyToPrograms < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :family, :string

    Program.connection.execute(
      'UPDATE programs set family = "vista_online_learning" where vista_online_learning is true'
    )
  end
end
