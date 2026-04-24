class AddTimeoutColumnsToSchoolConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :school_configs, :instructor_timeout, :integer
    add_column :school_configs, :student_timeout, :integer
    add_column :school_configs, :timeout_enabled, :boolean, default: false, null: false
  end
end
