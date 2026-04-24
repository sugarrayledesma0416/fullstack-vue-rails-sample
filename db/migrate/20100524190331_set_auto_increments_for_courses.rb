class SetAutoIncrementsForCourses < ActiveRecord::Migration[4.2]
  def self.up
    execute("ALTER TABLE courses AUTO_INCREMENT = 100000;")
  end

  def self.down
  end
end
