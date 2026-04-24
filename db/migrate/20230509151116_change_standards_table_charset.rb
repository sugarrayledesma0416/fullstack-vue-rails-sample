class ChangeStandardsTableCharset < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute 'ALTER TABLE standards CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci'
    end
  end
end
