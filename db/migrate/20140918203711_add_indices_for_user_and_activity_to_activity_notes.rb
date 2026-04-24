class AddIndicesForUserAndActivityToActivityNotes < ActiveRecord::Migration[4.2]
  def change
    add_index :activity_notes, [:user_id, :activity_id], name: 'by_user_and_activity'
  end
end

## To optimize this query
# SELECT `activity_notes`.* 
# FROM `activity_notes`  
# WHERE `activity_notes`.`activity_id` = 14971 
# AND `activity_notes`.`user_id` IN (325118)

## EXPLAIN Before adding index
# id     select_type     table           type     possible_keys     key     key_len     ref     rows     Extra       
# -----  --------------  --------------  -------  ----------------  ------  ----------  ------  -------  ----------- 
# 1      SIMPLE          activity_notes  ALL      (null)            (null)  (null)      (null)  87       Using where 

