namespace :dynamodb do
  desc 'Migrate dynamodb tables'
  task migrate: :environment do |cmd_name|
    existing_tables = DynamoConfig.client.list_tables.table_names

    [
      Xapi::ActivityState,
      Xapi::BasicAuthCredential,
      Xapi::Statement
    ].each do |klass|
      klass.migrate_up unless existing_tables.include?(klass.table_name)
    end
  end
end
