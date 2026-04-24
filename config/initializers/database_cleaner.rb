# The fix for this has been merged upstream:
# https://github.com/DatabaseCleaner/database_cleaner-active_record/pull/64
# But they haven't released a new gem version yet.
# Until then, this monkey patch corrects the problem.
if defined?(DatabaseCleaner)
  module DatabaseCleaner
    module ActiveRecord
      class Base
        private

        def load_config
          if db != :default && db.is_a?(Symbol) && File.file?(DatabaseCleaner::ActiveRecord.config_file_location)
            raw_yaml = ERB.new(
              IO.read(DatabaseCleaner::ActiveRecord.config_file_location)
            ).result
            connection_details = YAML.safe_load(raw_yaml, aliases: true)
            @connection_hash = valid_config(connection_details, db.to_s)
          end
        end
      end
    end
  end
end
