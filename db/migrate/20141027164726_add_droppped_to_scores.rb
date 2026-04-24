class AddDropppedToScores < ActiveRecord::Migration[4.2]
  def self.up
    alter_sql = "ALTER TABLE `scores` 
                              CHANGE COLUMN `pending` `pending` TINYINT(1) NOT NULL DEFAULT '0', 
                              CHANGE COLUMN `current` `current` TINYINT(1) NOT NULL DEFAULT '0', 
                              CHANGE COLUMN `adjusted` `adjusted` TINYINT(1) NOT NULL DEFAULT '0', 
                              CHANGE COLUMN `gradable` `gradable` TINYINT(1) NOT NULL DEFAULT '1', 
                              ADD COLUMN `dropped` TINYINT(1) NOT NULL DEFAULT '0'  AFTER `originally_due_at`, 
                              ADD INDEX `index_scores_on_dropped` (`dropped` ASC);"
    execute alter_sql
  end

  def self.down
    alter_sql = "ALTER TABLE `scores` 
                              CHANGE COLUMN `pending` `pending` TINYINT(1) DEFAULT '0', 
                              CHANGE COLUMN `current` `current` TINYINT(1) DEFAULT '0', 
                              CHANGE COLUMN `adjusted` `adjusted` TINYINT(1) DEFAULT '0', 
                              CHANGE COLUMN `gradable` `gradable` TINYINT(1) DEFAULT '1', 
                              DROP COLUMN `dropped`, 
                              DROP INDEX `index_scores_on_dropped`;"
    execute alter_sql
  end
end
