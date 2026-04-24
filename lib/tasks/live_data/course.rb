require 'tasks/print_decorator'

module LiveData
  class Course
      include  ::PrintDecorator

    attr_accessor :course

    def initialize(course_id = '')
      self.course = ::Course.find_by_id(course_id)
    end

    def export
      raise "Course with ID #{course.id} not found" unless course
      populate_connection_vars
      get_dump_from_m3
    end

    def populate_connection_vars
      print_message("Obtaining Maestro3 database configuration", '', 6)
      database_config_m3 = Rails.configuration.database_configuration[Rails.env]
      @m3_host     = database_config_m3["host"]
      @m3_db_user  = database_config_m3["username"]
      @m3_password = database_config_m3["password"]
      @m3_db_name  = database_config_m3["database"]

      @time = Time.new.to_i
    end
    private :populate_connection_vars

    def create_m3_dump_string(table_name, where_condition)
      print_message("processing Maestro3 table: #{table_name}", '', 6)
      execute_command("mysqldump -h #{@m3_host} -u #{@m3_db_user} --password='#{@m3_password}' --skip-triggers --compact --no-create-info --single-transaction --complete_insert #{@m3_db_name} #{table_name} --where='#{where_condition}' | sed 's/^INSERT/REPLACE/'") + "\n"
    end
    private :create_m3_dump_string

    def execute_command(command)
      message = "Executing: #{command}"
      print_message(message, '', 2, 'blue')
      `#{command}`
    end
    private :execute_command

    def get_dump_from_m3
      print_message("Retrieving Maestro3 data", 'H3', 2)

      sections = course.sections
      section_ids = sections.map(&:id).join(',')
      instructor_id = course.owner.id
      all_enrollments = sections.map(&:enrollments).flatten
      all_enrolled_student_ids = all_enrollments.map(&:user_id).join(',')
      categories = course.categories
      categories_ids = categories.collect(&:id).join(',')

      #course_id related dumps
      @m3_data = ''
      @m3_data <<  create_m3_dump_string('courses', "id = #{course.id}")
      @m3_data << create_m3_dump_string('sections', "course_id = #{course.id}")
      @m3_data << create_m3_dump_string('announcements', "course_id = #{course.id}")
      @m3_data << create_m3_dump_string('categories', "course_id = #{course.id}")

      #instructor_id related dumps
      populate_m3_schools(instructor_id)
      @m3_data << create_m3_dump_string('assignment_filters', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('grading_sets', "user_id = #{instructor_id}")  #filter by program?
      @m3_data << create_m3_dump_string('instructor_resource_settings', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('recordings', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('settings', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('section_instructors', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('users', "id = #{instructor_id}")
      @m3_data << create_m3_dump_string('school_users', "user_id = #{instructor_id}")
      @m3_data << create_m3_dump_string('roles_users', "user_id = #{instructor_id}")

      #user_ids of all students in the course related dumps
      @m3_data << create_m3_dump_string('recordings', "user_id in (#{all_enrolled_student_ids})")
      @m3_data << create_m3_dump_string('users', "id in (#{all_enrolled_student_ids})")
      @m3_data << create_m3_dump_string('school_users', "user_id in (#{all_enrolled_student_ids})")
      @m3_data << create_m3_dump_string('roles_users', "user_id in (#{all_enrolled_student_ids})")
      @m3_data << create_m3_dump_string('partner_chat_recordings', "user_id in (#{all_enrolled_student_ids})")

      #section_ids of all sections in the course related dumps
      @m3_data << create_m3_dump_string('assignments', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('attempts', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('feedback_items', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('notifications', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('section_instructors', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('student_spotcheck_counts', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('worksets', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('enrollments', "section_id in (#{section_ids})")
      @m3_data << create_m3_dump_string('help_requests', "section_id in (#{section_ids})")

      #category_ids of all categories in the course related dumps
      @m3_data << create_m3_dump_string('scoring_rulesets', "category_id in (#{categories_ids})")

      print_message("Maestro3 data retrieved", 'H3', 2, 'green')
      create_dump_file(@m3_data, 'm3')
    end
    private :get_dump_from_m3

    def populate_m3_schools(instructor_id)
      instructor_schools_ids = Instructor.find_by_id(instructor_id).schools.collect{|school| school.id}
      @m3_data << create_m3_dump_string('schools', "id in (#{instructor_schools_ids.join(',')})") unless instructor_schools_ids.blank?
    end
    private :populate_m3_schools

    def create_dump_file(data, master)
      file_name = "#{master}_#{course.id}.sql"
      File.open("/tmp/#{file_name}", "w") do |file|
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

    def import(course_id)
      populate_connection_vars
      import_m3_course_from_dump_file(course_id)
      print_message("Course data retrieved", 'H3', 2, 'green')
    end

    def import_m3_course_from_dump_file(course_id)
      m3_dump_file = "/tmp/m3_#{course_id}.sql"
      raise "File #{m3_dump_file} not found" unless File.exist?(m3_dump_file)

      print_message("Retrieving Maestro3 data", 'H3', 2)
      execute_command("mysql -h #{@m3_host} -u #{@m3_db_user} --password='#{@m3_password}' --default_character_set utf8 #{@m3_db_name} < #{m3_dump_file}")
    end

  end
end
