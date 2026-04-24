class AddIndexForSectionIdAndCreatedAtToAnnouncements < ActiveRecord::Migration[4.2]
  def change
    add_index :announcements, [:section_id, :created_at], order: {created_at: :desc}, name: 'by_section_sort_by_created_at_desc' 
  end
end

## To optimize this query
# SELECT `announcements`.* 
# FROM `announcements`  
# WHERE `announcements`.`is_archived` = 0 
# AND `announcements`.`section_id` IN (277053) 
# ORDER BY announcements.created_at DESC

### EXPLAIN Before adding index
#  id     select_type     table          type     possible_keys     key     key_len     ref     rows     Extra                       
#  -----  --------------  -------------  -------  ----------------  ------  ----------  ------  -------  --------------------------- 
#  1      SIMPLE          announcements  ALL      (null)            (null)  (null)      (null)  19512    Using where; Using filesort 

