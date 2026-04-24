class AddUserAndActivityIndexToHelpRequests < ActiveRecord::Migration[4.2]
  def change
    add_index :help_requests, [:user_id, :activity_id], :name => 'by_user_and_activity'
  end
end

## To optimize this query:
# SELECT `help_requests`.*
# FROM `help_requests`
# WHERE `help_requests`.`request_type` IN ('request_help', 'request_review')
# AND `help_requests`.`user_id` IN (2153405)
# AND `help_requests`.`activity_id` = 20713

## EXPLAIN Before adding index
# id     select_type     table          type     possible_keys     key     key_len     ref     rows     Extra
# -----  --------------  -------------  -------  ----------------  ------  ----------  ------  -------  -----------
# 1      SIMPLE          help_requests  ALL      (null)            (null)  (null)      (null)  104946   Using where
