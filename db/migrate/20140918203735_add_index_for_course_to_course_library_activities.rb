class AddIndexForCourseToCourseLibraryActivities < ActiveRecord::Migration[4.2]
  def change
    add_index :course_library_activities, :course_id, name: 'by_course'
  end
end

## To optimize this query
# SELECT activities.id, course_library_activities.hidden 
# FROM `activities` 
# INNER JOIN `course_library_activities` ON `course_library_activities`.`activity_id` = `activities`.`id` 
# WHERE `activities`.`lesson_id` = 297 
# AND `course_library_activities`.`course_id` = 231392 
# AND (activities.instructor_revision_id is not null)

## EXPLAIN Before adding index
# id     select_type     table                      type     possible_keys                                         key      key_len     ref                                       rows     Extra       
# -----  --------------  -------------------------  -------  ----------------------------------------------------  -------  ----------  ----------------------------------------  -------  ----------- 
# 1      SIMPLE          course_library_activities  ALL      index_course_activities_on_activity_id_and_course_id  (null)   (null)      (null)                                    191      Using where 
# 1      SIMPLE          activities                 eq_ref   PRIMARY,index_activities_on_lesson_id                 PRIMARY  4           m3.course_library_activities.activity_id  1        Using where 
#

