namespace :maintenance do
  desc "environment setup test task"
  task :environment_test => :environment do
    result = ActiveRecord::Base.connection.execute("SHOW TABLES")
    result.each do |row|
      puts row[0]
    end
  end
end
