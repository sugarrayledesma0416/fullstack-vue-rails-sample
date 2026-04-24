class AddIndexForVocabProgramGroupIdToPrograms < ActiveRecord::Migration[4.2]
  def change
    add_index :programs, :vocab_program_group_id, name: 'by_vocab_program_group'
  end
end

## To optimize this query
# SELECT `programs`.id 
# FROM `programs`  
# WHERE `programs`.`vocab_program_group_id` = 52

## EXPLAIN Before adding index
# id     select_type     table     type     possible_keys     key     key_len     ref     rows     Extra       
# -----  --------------  --------  -------  ----------------  ------  ----------  ------  -------  ----------- 
# 1      SIMPLE          programs  ALL      (null)            (null)  (null)      (null)  72       Using where 

