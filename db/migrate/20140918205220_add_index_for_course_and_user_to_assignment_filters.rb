class AddIndexForCourseAndUserToAssignmentFilters < ActiveRecord::Migration[4.2]
  def change
    add_index :assignment_filters, [:course_id, :user_id], name: 'by_course_and_user'
  end
end

## To optimize this query
# SELECT  `assignment_filters`.* 
# FROM `assignment_filters`  
# WHERE `assignment_filters`.`course_id` = 222693 
# AND `assignment_filters`.`user_id` = 339175 
# LIMIT 1

## EXPLAIN Before adding index
# id     select_type     table               type     possible_keys     key     key_len     ref     rows     Extra       
# -----  --------------  ------------------  -------  ----------------  ------  ----------  ------  -------  ----------- 
# 1      SIMPLE          assignment_filters  ALL      (null)            (null)  (null)      (null)  14546    Using where 

