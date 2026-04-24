class AddProgramIdIndexToDefaultVocabWords < ActiveRecord::Migration[4.2]
  def change
    add_index :default_vocab_words, :program_id, name: 'by_program'
  end
end

## To optimize this query
# SELECT d.id, NULL as user_id, NULL as default_vocab_word_id, l.name as lesson_name, 
# d.lesson_id, d.target_word, d.base_word, d.target_definition, 
# d.language, d.created_at, 0 as archived, 1 as default_vocab_word, 
# d.vocab_program_group_id, d.program_id 
# FROM default_vocab_words as d 
# LEFT OUTER JOIN vocab_words v ON d.id = v.default_vocab_word_id AND v.user_id = 2030718
# LEFT JOIN lessons l ON l.id = d.lesson_id 
# WHERE (v.id is null AND d.program_id IN (61)) 
# ORDER BY d.created_at DESC, d.id DESC;

## EXPLAIN Before adding index
#  id     select_type     table     type     possible_keys                   key                             key_len     ref             rows     Extra                                
#  -----  --------------  --------  -------  ------------------------------  ------------------------------  ----------  --------------  -------  ------------------------------------ 
#  1      SIMPLE          d         ALL      (null)                          (null)                          (null)      (null)          25530    Using where; Using filesort          
#  1      SIMPLE          v         ref      by_user_and_default_vocab_word  by_user_and_default_vocab_word  10          const,m3.d.id   1        Using where; Using index; Not exists 
#  1      SIMPLE          l         eq_ref   PRIMARY                         PRIMARY                         4           m3.d.lesson_id  1                                             

