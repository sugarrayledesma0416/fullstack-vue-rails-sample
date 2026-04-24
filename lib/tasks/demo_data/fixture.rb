
module DemoData

  module Fixture
    require 'active_record/fixtures'

    def self.load(table_name)
      puts "loading fixture #{table_name}"
      ActiveRecord::Fixtures.create_fixtures(Rails.root.join('db', 'example_data'), table_name )
    end

    def self.active_record_load(klass)
      message = "active record load for #{klass.to_s}"
      puts "starting  #{message}"

      input_file = File.join('db', 'example_data', "#{klass.to_s.tableize}.csv")

      DemoData::CSV.rows(input_file) do |row|
        record = klass.new(row)
        record.id = row[:id]
        record.save!
      end

      puts "completed #{message}"
    end
  end

end
