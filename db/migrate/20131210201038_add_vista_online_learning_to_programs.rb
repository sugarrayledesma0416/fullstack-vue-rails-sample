class AddVistaOnlineLearningToPrograms < ActiveRecord::Migration[4.2]
  def change
    add_column :programs, :vista_online_learning, :boolean, :default => false, :null => false
  end
end
