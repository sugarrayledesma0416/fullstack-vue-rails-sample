class AddRosteringFieldsToSectionInstructors < ActiveRecord::Migration[4.2]
  def self.up
    alter_sql = "ALTER TABLE `section_instructors`
                              ADD COLUMN `guid`  VARCHAR(255),
                              ADD COLUMN `sync_token` BIGINT(20) DEFAULT '0',
                              ADD COLUMN `request_id`  VARCHAR(255),
                              ADD UNIQUE INDEX `index_section_instructors_on_guid` (`guid`)"
    execute alter_sql
  end

  def self.down
    alter_sql = "ALTER TABLE `section_instructors`
                              DROP COLUMN `guid`,
                              DROP COLUMN `sync_token`,
                              DROP COLUMN `request_id`,
                              DROP INDEX `index_section_instructors_on_guid`;"
    execute alter_sql
  end
end
