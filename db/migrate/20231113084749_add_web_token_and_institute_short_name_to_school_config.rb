class AddWebTokenAndInstituteShortNameToSchoolConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :school_configs, :web_token, :string
    add_column :school_configs, :institute_short_name, :string
  end
end
