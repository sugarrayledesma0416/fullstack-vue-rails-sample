class AddResourceIdIndexToInstructorResourceSettings < ActiveRecord::Migration[4.2]
  def change
    add_index :instructor_resource_settings, :resource_id
  end
end

## To optimize this query:
# SELECT `instructor_resource_settings`.*
# FROM `instructor_resource_settings`
# WHERE `instructor_resource_settings`.`resource_id` IN (29573, 29576, 29574, 29575);

## EXPLAIN Before adding index
# id     select_type     table                         type     possible_keys     key     key_len     ref     rows     Extra
# -----  --------------  ----------------------------  -------  ----------------  ------  ----------  ------  -------  -----------
# 1      SIMPLE          instructor_resource_settings  ALL      (null)            (null)  (null)      (null)  12398    Using where
