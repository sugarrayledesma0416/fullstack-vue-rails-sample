class AddUserIdIndexToSectionInstructors < ActiveRecord::Migration[4.2]
  def change
    add_index :section_instructors, :user_id
  end
end

## To optimize this query:
# SELECT `sections`.* FROM `sections`
# INNER JOIN `section_instructors` ON `sections`.`id` = `section_instructors`.`section_id`
# WHERE `sections`.`is_archived` = 0 AND `section_instructors`.`user_id` = 2511501

## EXPLAIN Before adding index
# id     select_type     table                type     possible_keys        key                  key_len     ref                   rows     Extra
# -----  --------------  -------------------  -------  -------------------  -------------------  ----------  --------------------  -------  ------------------------
# 1      SIMPLE          sections             ALL      PRIMARY              (null)               (null)      (null)                58193    Using where
# 1      SIMPLE          section_instructors  ref      by_section_and_user  by_section_and_user  10          m3.sections.id,const  1        Using where; Using index
