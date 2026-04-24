class AddRosteringFieldsToCourses < ActiveRecord::Migration[4.2]
  def self.up
    alter_sql = "ALTER TABLE `courses`
                              ADD COLUMN `guid`  VARCHAR(255),
                              ADD COLUMN `sync_token` BIGINT(20) DEFAULT '0',
                              ADD COLUMN `request_id`  VARCHAR(255),
                              ADD UNIQUE INDEX `index_courses_on_guid` (`guid`)"
    execute alter_sql
  end

  def self.down
    alter_sql = "ALTER TABLE `courses`
                              DROP COLUMN `guid`,
                              DROP COLUMN `sync_token`,
                              DROP COLUMN `request_id`,
                              DROP INDEX `index_courses_on_guid`;"
    execute alter_sql
  end
end
