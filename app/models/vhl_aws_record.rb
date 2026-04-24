module VhlAwsRecord
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.include(Aws::Record)
    klass.configure_client(client: DynamoConfig.client)
  end

  module ClassMethods
    def prefix_table_name(table_name)
      Rails.env.test? ? "test_#{table_name}" : table_name
    end

    def migrate_up
      verify_migration_safety
      migration.create!(
        billing_mode: 'PAY_PER_REQUEST',
        global_secondary_index_throughput: global_index_throughput
      )
    end

    def migrate_down
      verify_migration_safety
      begin
        migration.delete!
      rescue Aws::Record::Errors::TableDoesNotExist
        # Don't throw error if this runs before table exists
        true
      end
    end

    def verify_migration_safety
      return if DynamoConfig.use_local?
      raise 'DynamoDb migrations can only be run against local dynamodb'
    end

    def migration
      Aws::Record::TableMigration.new(self, client: dynamodb_client)
    end

    def global_index_throughput
      global_secondary_indexes.keys.each_with_object({}) do |name, memo|
        memo[name] = { read_capacity_units: 5, write_capacity_units: 5 }
      end
    end
  end
end
