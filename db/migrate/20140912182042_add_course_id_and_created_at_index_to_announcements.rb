class AddCourseIdAndCreatedAtIndexToAnnouncements < ActiveRecord::Migration[4.2]
  def change
    add_index :announcements, [:course_id, :created_at], order: {created_at: :desc}, name: 'by_course_sort_by_created_at_desc' 
  end
end

## To optimize this query
# SELECT `announcements`.* 
# FROM `announcements`  
# WHERE `announcements`.`is_archived` = 0 
# AND `announcements`.`course_id` IN (217547) 
# AND (announcements.section_id IS NULL) 
# ORDER BY announcements.created_at DESC

## EXPLAIN Before adding index
#  id     select_type     table          type     possible_keys     key     key_len     ref     rows     Extra                       
#  -----  --------------  -------------  -------  ----------------  ------  ----------  ------  -------  --------------------------- 
#  1      SIMPLE          announcements  ALL      (null)            (null)  (null)      (null)  1        Using where; Using filesort 

## Adding the order_by created_at eliminates the filesort operation.

