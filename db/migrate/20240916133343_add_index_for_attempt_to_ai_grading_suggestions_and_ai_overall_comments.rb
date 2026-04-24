class AddIndexForAttemptToAIGradingSuggestionsAndAIOverallComments < ActiveRecord::Migration[6.1]
  def change
    add_index :ai_grading_suggestions, :attempt_id, name: 'index_ai_grading_suggestions_on_attempt_id'
    add_index :ai_overall_comments, :attempt_id, name: 'index_ai_overall_comments_on_attempt_id'

    ## To improve this query:
    # SELECT DISTINCT attempts.* 
    # FROM attempts 
    # LEFT OUTER JOIN ai_grading_suggestions ON ai_grading_suggestions.attempt_id = attempts.id 
    # LEFT OUTER JOIN ai_overall_comments ON ai_overall_comments.attempt_id = attempts.id 
    # WHERE attempts.activity_id = <activity_id> 
    #   AND (
    #     ai_grading_suggestions.question_label = <question_label>
    #     AND ai_grading_suggestions.prompt_id = <prompt_id>  
    #     AND ai_grading_suggestions.rated_by_id IS NOT NULL 
    #     OR ai_overall_comments.question_label = <question_label>
    #     AND ai_overall_comments.prompt_id = <prompt_id>  
    #     AND ai_overall_comments.rated_by_id IS NOT NULL
    #   ) 
    # LIMIT 10 OFFSET 0;
    ## Note that cardinality of prompt_id, rated_by_id and question_label are very low, so have not been indexed
    #
    ## Explain plan:
    # =+------+-------------+------------------------+------+-------------------------------+-------------------------------+---------+-------+--------+--------------------------------------------------------+
    # | id   | select_type | table                  | type | possible_keys                 | key                           | key_len | ref   | rows   | Extra                                                  |
    # +------+-------------+------------------------+------+-------------------------------+-------------------------------+---------+-------+--------+--------------------------------------------------------+
    # |    1 | SIMPLE      | attempts               | ref  | index_attempts_on_activity_id | index_attempts_on_activity_id | 5       | const | 8989   | Using temporary                                        |
    # |    1 | SIMPLE      | ai_grading_suggestions | ALL  | NULL                          | NULL                          | NULL    | NULL  | 126653 | Using where; Using join buffer (flat, BNL join)        |
    # |    1 | SIMPLE      | ai_overall_comments    | ALL  | NULL                          | NULL                          | NULL    | NULL  | 87982  | Using where; Using join buffer (incremental, BNL join) |
    # +------+-------------+------------------------+------+-------------------------------+-------------------------------+---------+-------+--------+--------------------------------------------------------+
  end
end
