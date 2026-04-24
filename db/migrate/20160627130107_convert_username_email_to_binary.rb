class ConvertUsernameEmailToBinary < ActiveRecord::Migration[4.2]
  def self.up
    # apply binary collation to allow case sensitive searches and
    # enable the finding of values with accented characters
    # this migration will also take about 10 minutes per field on live
    execute %{alter table users 
                MODIFY username varchar(255) COLLATE utf8_bin NOT NULL,
                MODIFY email varchar(255) COLLATE utf8_bin NOT NULL}
  end

  def self.down
    execute %{alter table users 
                MODIFY username varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                MODIFY email varchar(255) COLLATE utf8_unicode_ci NOT NULL}
  end
end
