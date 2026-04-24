class AddIndexForJidToScheduledJobs < ActiveRecord::Migration[4.2]
  def change
    add_index :scheduled_jobs, :jid
  end
end

## To optimize this query
#  SELECT  `scheduled_jobs`.* FROM `scheduled_jobs`  
#  WHERE `scheduled_jobs`.`jid` = '5542f698eafd575df20f56d0' 
#  LIMIT 1

##  EXPLAIN Before adding index
#  id     select_type     table           type     possible_keys     key     key_len     ref     rows     Extra       
#  -----  --------------  --------------  -------  ----------------  ------  ----------  ------  -------  ----------- 
#  1      SIMPLE          scheduled_jobs  ALL      (null)            (null)  (null)      (null)  8        Using where 
