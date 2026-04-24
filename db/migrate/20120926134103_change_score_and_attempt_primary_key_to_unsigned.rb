class ChangeScoreAndAttemptPrimaryKeyToUnsigned < ActiveRecord::Migration[4.2]
  def self.up
    execute "ALTER TABLE scores MODIFY id INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE attempts MODIFY id INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT"
  end

  def self.down
    execute "ALTER TABLE scores MODIFY id INTEGER(11) NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE attempts MODIFY id INTEGER(11) NOT NULL AUTO_INCREMENT"
  end
end
