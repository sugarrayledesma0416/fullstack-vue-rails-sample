class AddIndexForSectionAndActivityToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_index :notifications, [:section_id, :activity_id], name: 'by_section_and_activity'
  end
end

## To optimize this query
# DELETE FROM `notifications` 
# WHERE `notifications`.`activity_id` = 14047 
# AND `notifications`.`type` IN ('ExternalActivityNotification', 'ScoreChangeExternalActivityNotification') 
# AND `notifications`.`section_id` IN (245557)

# Converted for EXPLAIN
# select * 
# from  `notifications` 
# WHERE `notifications`.`activity_id` = 14047 
# AND `notifications`.`type` IN ('ExternalActivityNotification', 'ScoreChangeExternalActivityNotification') 
# AND `notifications`.`section_id` IN (245557)

## EXPLAIN Before adding index
# id     select_type     table          type     possible_keys     key     key_len     ref     rows     Extra       
# -----  --------------  -------------  -------  ----------------  ------  ----------  ------  -------  ----------- 
# 1      SIMPLE          notifications  ALL      (null)            (null)  (null)      (null)  2922167  Using where 

