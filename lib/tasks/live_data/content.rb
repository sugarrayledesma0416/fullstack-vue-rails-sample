require 'tasks/print_decorator'

module LiveData
  class Content
    include ::PrintDecorator

    CONTENT_TABLES = %w[
      activities
      assessment_items
      concepts
      default_vocab_tags
      default_vocab_words
      default_vocabulary_words
      ereader_items
      lessons
      media_items
      program_configs
      program_editions
      program_to_program_mappings
      program_media_items
      programs
      question_bank_revisions
      resource_components
      resources
      rubric_criteria_scores
      schools
      standard_alignments
      standard_assets
      standard_sets
      standards
      study_plan_concept_recommendations
      study_plan_concepts
      track_groups
      question_bank_topics
      question_bank_topics_concepts
      units
      vocab_program_groups
    ].freeze

    def export
      populate_connection_vars
      get_content_dump
    end

    def import
      populate_connection_vars
      truncate_content_tables
      import_m3_sql_data
      print_message('Content data retrieved', 'H3', 2, 'green')
    end

    def make_activity_content_local(activity_id)
      raise 'Do not run on a live server!' if Rails.env.live?

      activity = Activity.find(activity_id)

      if activity.cdn?
        content = activity.content
        activity.update(cdn: false)
        activity = Activity.find(activity_id) # reload is not sufficient

        if File.exist?(activity.content_filepath)
          puts "\nOVERWRITE WARNING! #{activity.content_filepath} exists! Rename or remove it and try again."
          activity.update(cdn: true) # restore cdn state
        else
          activity.activity_content.store_content(content)
          puts "\nActivity #{activity_id} configured for local access."
          puts "File path: #{activity.content_filepath}"
        end
      else
        puts "\nERROR! Activity #{activity_id} is already configured for local access."
      end
    end

    def generate_fake_resources_files
      print_message('Generating fake resources files', 'H3', 2)

      Resource.all.each do |resource|
        unless File.exist?(resource.file_path)
          create_files_for(resource)
        end
      end
    end

    def create_files_for(resource)
      contents = Lorem::Base.new('words', '100').output
      FileUtils.makedirs(File.dirname(resource.file_path))
      File.open(resource.file_path, 'w') { |file| file.write(contents) }
      print_message("Created file #{resource.file_path}", '', 2, 'blue')
    end
    private :create_files_for

    def import_m3_sql_data
      content_data_file = '/tmp/content_data_m3.sql'
      raise "File #{content_data_file} not found" unless File.exist?(content_data_file)

      print_message("Retrieving Maestro3 content data from #{content_data_file}", 'H3', 2)
      execute_command("mysql -h #{@m3_host} -u #{@m3_db_user} -P #{@m3_db_port} --password='#{@m3_password}' --default_character_set utf8 #{@m3_db_name} < #{content_data_file}")
    end
    private :import_m3_sql_data

    def get_content_dump
      # so far we want to dump entire tables,
      content_data = ''
      CONTENT_TABLES.each do |table_name|
        where_condition = if table_name == 'schools'
                            schools_skip_condition
                          else
                            ''
                          end
        content_data << create_dump_string(table_name, where_condition)
      end
      print_message('Maestro3 content data retrieved', 'H3', 2, 'green')
      create_dump_file(content_data, 'm3')
    end

    def create_dump_string(table_name, where_condition = '')
      print_message("processing Maestro3 table: #{table_name}", '', 6)
      where = where_condition.blank? ? '' : "--where='#{where_condition}'"
      execute_command("mysqldump -h #{@m3_host} -u #{@m3_db_user} -P #{@m3_db_port} --password='#{@m3_password}' --skip-triggers --compact --no-create-info --single-transaction --complete_insert #{@m3_db_name} #{table_name} #{where} | sed 's/^INSERT/REPLACE/'") + "\n"
    end
    private :create_dump_string

    def create_dump_file(data, master)
      file_name = "content_data_#{master}.sql"
      File.open("/tmp/#{file_name}", 'w') do |file|
        file.write(data)
      end

      maestro_name = case master
                     when 'm3' then 'Maestro3'
                     else
                       ''
                     end
      print_message("#{maestro_name} dump file created on [/tmp/#{file_name}]", 'H3', 1, 'blue')
    end
    private :create_dump_file

    def execute_command(command)
      message = "Executing: #{command}"
      print_message(message, '', 2, 'blue')
      `#{command}`
    end
    private :execute_command

    def populate_connection_vars
      desired_environment = ENV['env'] || Rails.env
      print_message('Obtaining Maestro3 database configuration', '', 6)
      database_config_m3 = Rails.configuration.database_configuration[desired_environment]
      raise "Database configuration missing for #{desired_environment}" unless database_config_m3.present?
      @m3_host     = database_config_m3['host']
      @m3_db_user  = database_config_m3['username']
      @m3_password = database_config_m3['password']
      @m3_db_name  = database_config_m3['database']
      @m3_db_port  = database_config_m3['port'] || 3306

      @time = Time.new.to_i
    end
    private :populate_connection_vars

    def truncate_content_tables
      connection = ActiveRecord::Base.connection
      CONTENT_TABLES.each do |table_name|
        if table_name == 'schools'
          connection.execute("DELETE FROM #{table_name} WHERE #{schools_skip_condition};")
        else
          connection.execute("truncate table #{table_name};")
        end
      end
    end
    private :truncate_content_tables

    private def schools_skip_condition
      # school records with sales_rep_id = 9, where created exclusively for the QA snapshot
      # and are not live, we don't want to lose them.
      "id NOT IN (#{School.where(sales_rep_id: 9).pluck(:id).join(',')})"
    end
  end
end
