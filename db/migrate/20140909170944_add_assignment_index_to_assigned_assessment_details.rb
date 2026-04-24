class AddAssignmentIndexToAssignedAssessmentDetails < ActiveRecord::Migration[4.2]
  def change
    add_index :assigned_assessment_details, :assignment_id
  end
end

## To optimize this query:
# SELECT  `assigned_assessment_details`.*
# FROM `assigned_assessment_details`
# WHERE `assigned_assessment_details`.`assignment_id` = 5060249 LIMIT 1

## EXPLAIN Before adding index
#  id     select_type     table                        type     possible_keys     key     key_len     ref     rows     Extra
#  -----  --------------  ---------------------------  -------  ----------------  ------  ----------  ------  -------  -----------
#  1      SIMPLE          assigned_assessment_details  ALL      (null)            (null)  (null)      (null)  738450   Using where

