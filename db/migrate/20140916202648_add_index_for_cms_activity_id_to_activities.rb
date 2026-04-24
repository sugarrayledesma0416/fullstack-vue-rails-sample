class AddIndexForCmsActivityIdToActivities < ActiveRecord::Migration[4.2]
  def change
    add_index :activities, :cms_activity_id
  end
end

## To optimize this query
# SELECT  `activities`.* 
# FROM `activities`  
# WHERE `activities`.`cms_activity_id` = 60902 
# LIMIT 1

## EXPLAIN Before adding index
# id     select_type     table       type     possible_keys     key     key_len     ref     rows     Extra       
# -----  --------------  ----------  -------  ----------------  ------  ----------  ------  -------  ----------- 
# 1      SIMPLE          activities  ALL      (null)            (null)  (null)      (null)  40443    Using where

