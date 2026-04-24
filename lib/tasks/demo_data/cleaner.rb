module DemoData
  class Cleaner
    DATAFILES_HOME = File.join('datafiles', Rails.env)

    def delete_all_courses_and_student_work
      puts 'deleting all courses and student work'
      course_and_student_work_tables = %w[
        announcements assignment_filters assignments attempts
        categories chat_click_logs
        courses delayed_jobs enrollments events
        feedback_items general_logs grades grading_sets
        instructor_resource_settings notifications recordings
        scoring_rulesets
        section_instructors sections settings student_spotcheck_counts
        worksets
      ]
      course_and_student_work_tables.each do |table_name|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
      end
    end

    def delete_all_resources
      puts 'deleting all resource records'
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE resources')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE resource_components')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE instructor_resource_settings')

      puts 'deleting all resource files'
      resources_dir = Rails.root.join('resources', Rails.env)
      DemoData::DataFile.delete_dir(resources_dir)
    end

    def delete_all_response_xml_files
      puts 'deleting all student response xml files'

      responses_dir = File.join(DATAFILES_HOME, 'responses')
      DemoData::DataFile.delete_dir(responses_dir)
    end

    def delete_all_user_log_csv_files
      puts 'deleting all user log csv files'

      user_logs_dir = File.join('log', Rails.env, 'user')
      DemoData::DataFile.delete_dir(user_logs_dir)
    end

    def delete_all_activity_xml_files
      puts 'deleting all activity xml files'

      activities_dir = File.join(DATAFILES_HOME, 'activities')
      DemoData::DataFile.delete_dir(activities_dir)
    end
  end
end
