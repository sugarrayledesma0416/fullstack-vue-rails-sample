class AddUniqueIndexToUsernameAndEmail < ActiveRecord::Migration[4.2]
  def self.up
    execute %{ALTER TABLE users
                DROP INDEX `index_users_on_email`,
                ADD UNIQUE INDEX `index_users_on_email` (`email` ASC),
                DROP INDEX `index_users_on_username`,
                ADD UNIQUE INDEX `index_users_on_username` (`username` ASC)}
  end

  def self.down
    execute %{ALTER TABLE users
                DROP INDEX `index_users_on_email`,
                ADD INDEX `index_users_on_email` (`email` ASC),
                DROP INDEX `index_users_on_username`,
                ADD INDEX `index_users_on_username` (`username` ASC)}
  end
end

