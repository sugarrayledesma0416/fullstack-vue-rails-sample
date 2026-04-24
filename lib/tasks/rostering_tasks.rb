class RosteringTasks

  SQL_IP_FILENAME = "/tmp/m3_sql_assigment_guids_%s.sql"
  RESULTS_FILENAME = "/tmp/m3_ids_as_guids_results_%s.txt"

  TABLES_FOR_IDS = %w(user course section enrollment school)
  TABLES_SQL_ASSIGNED_GUIDS = %w(section_instructor school_user)

  SPECIAL_TABLE_COLUMN_NAMES = { "section_instructor"=>["section_id", "user_id"], "school_user"=>["school_id", "user_id"] }


  def assign_and_load_guids_from_file(retain_file)
    @desired_environment = Rails.env
    @mysql_filename = SQL_IP_FILENAME % @desired_environment
    # write results to a file for post-mortem review
    @results_file_name = RESULTS_FILENAME % @desired_environment
    prep_for_tasks
    puts "Review results in output file '#{@results_file_name}'"
    populate_connection_vars
    populate_guids_with_ids unless Rails.env.live?
    import_m3_sql_data
    output_sql_assigned_results
    cleanup unless retain_file
  end

  def modify_database_ids
    if Rails.env.live?
         puts "Modifying database ids to mismatch should only be run in a test environment"
         return
    end
    modify_users_and_related
    modify_schools_and_related
    bump_ids
  end

  private def populate_connection_vars
    database_config_m3 = Rails.configuration.database_configuration[@desired_environment]
    raise "Database configuration missing for '#{@desired_environment}'" unless database_config_m3.present?
    @m3_host     = database_config_m3["host"]
    @m3_db_user  = database_config_m3["username"]
    @m3_password = database_config_m3["password"]
    @m3_db_name  = database_config_m3["database"]
  end

  private def populate_guids_with_ids
    TABLES_FOR_IDS.each { |t| populate_table_guids_with_ids(t)  }
  end

  ## assign the id to the guid column, output to results file for comparison against UA results
  private def populate_table_guids_with_ids(table_name)
    puts "Updating Maestro3 table '#{table_name}s' assigning id to guid column..."
    klass = table_name.camelize.constantize
    klass.find_each do |obj|
      # use update_column to avoid all callbacks
      obj.update_column(:guid, obj.id)
      File.open(@results_file_name, "a+") {|file| file.puts "table: #{table_name}s id: #{obj.id} guid: #{obj.guid}"}
    end
  end

  private def import_m3_sql_data
    puts "Populating Maestro3 guids from " + @mysql_filename + "..."
    execute_command("mysql -h #{@m3_host} -u #{@m3_db_user} --password='#{@m3_password}' --default_character_set utf8 #{@m3_db_name} < #{@mysql_filename}")
  end

  # For the tables that were populated via a SQL script, output the results so that
  # it can be compared against the results file from UA.
  private def output_sql_assigned_results
    TABLES_SQL_ASSIGNED_GUIDS.each { |t| output_special_table_guids(t)  }
  end

  private def output_special_table_guids(table_name)
    puts "Writing guids for Maestro3 table #{table_name}..."
    col_names = SPECIAL_TABLE_COLUMN_NAMES[table_name]
    klass = table_name.camelize.constantize
    klass.find_each do |obj|
      File.open(@results_file_name, "a+") { |file| file.puts "table: #{table_name}s #{col_names[0]}: #{obj.send(col_names[0])} #{col_names[1]}:#{obj.send(col_names[1])} guid: #{obj.guid} id: #{obj.id}" }
    end
  end

  private def execute_command(command)
    `#{command}`
  end

  private def prep_for_tasks
    # make sure that the SQL commands file exists
    raise "File '#{@mysql_filename}' not found. Did you run the UA rake task 'rostering_tasks:assign_guids' that generates this file?" unless File.exist?(@mysql_filename)
    # remove results from a prior run
    if File.exist?(@results_file_name)
      File.delete(@results_file_name)
    end
  end

  # After the SQL commands are run, remove the file so it can't be reused.
  # this prevents someone from successfully executing this rake task if
  # they forgot to run the UA rake task and have an old file hanging around.
  private def cleanup
    if File.exist?(@mysql_filename)
       File.delete(@mysql_filename)
    end
  end

  def modify_users_and_related
    # read all users, for each one create a copy, update matching school users
    # and roles users with new user_id, update any setting if there is one; update
    # schools where this user is salesrep and change the salesrep_id;
    # save everything, archive original user
    puts "User first id #{User.unscoped.find(:all).first.id}"
    puts "User last id #{User.unscoped.find(:all).last.id}"
    users = User.find(:all)
    users.each do | user |
      copy_user = user.dup
      # munging these allows the copy to be saved
      # without violating uniqueness constraints;
      # add user id to archived username and email so this can be run multiple times withou failing
      user.update_column(:username, 'ARCHIVED' + user.id.to_s + user.username)
      user.update_column(:email, user.email + "ARCHIVED" + user.id.to_s)
      copy_user.save!(validate: false)
      school_users = SchoolUser.where(user_id: user.id)
      school_users.each do |su|
        su.update_column(:user_id, copy_user.id)
      end
      # RolesUsers does not have a primary key so updating the user_id column
      # fails and throws an exception; instead need to create a new RolesUser instance
      # with the new user_id and save it.
      roles_users = RolesUser.where(user_id: user.id)
      roles_users.each do |ru|
        new_roles_user = ru.dup
        new_roles_user.user_id = copy_user.id
        new_roles_user.save!(validate: false)
        # deleting the old one returns an error so it becomes an orphan record
        begin
          ru.delete
        rescue Exception => e
          # deleting the old one fails so it becomes an orphan record
          # puts "Error attempting to delete RolesUser for user: #{ru.user_id} #{e}"
        end
      end
      schools = School.where(sales_rep_id: user.id)
      schools.each do |s|
        s.update_column(:sales_rep_id, copy_user.id)
      end
      setting = Setting.where(user_id: user.id).first
      setting.update_column(:user_id, copy_user.id) unless setting.nil?
      # delete vs destroy ensures no callbacks made
      user.delete
    end
    puts "Updated User first id #{User.unscoped.find(:all).first.id}"
    puts "Updated User last id #{User.unscoped.find(:all).last.id}"
  end

  def modify_schools_and_related
    # read all schools, for each one create a copy, update matching school users
    # and schools with this one as related district with new school_id, update any setting if there is one;
    # save everything, archive original school
    puts "School first id #{School.unscoped.find(:all).first.id}"
    puts "School last id #{School.unscoped.find(:all).last.id}"
    district_ids = Hash.new
    schools = School.find(:all)
    schools.each do |school|
      copy_school = school.dup
      copy_school.save!(validate: false)
      district_ids.store(school.id.to_s, copy_school.id.to_s)
      school_users = SchoolUser.where(school_id: school.id)
      school_users.each do |su|
        su.update_column(:school_id, copy_school.id)
      end
      # delete vs destroy ensures no callbacks made
      school.delete
    end
    # now fix the district_ids
    district_ids.each do |old_district_id, new_district_id|
      old_district_id_int = old_district_id.to_i
      new_district_id_int = new_district_id.to_i
      puts "Looking for schools with district_id: #{old_district_id}"
      district_schools = School.where(district_id: old_district_id_int)
      district_schools.each do |ds|
        puts "updating school #{ds.id} old district_id #{ds.district_id} with new district_id #{new_district_id_int}"
        ds.update_column(:district_id, new_district_id_int)
        puts "After modifying new district_id is: #{ds.district_id} "
      end
    end
    puts "Updated School first id #{School.unscoped.find(:all).first.id}"
    puts "Updated School last id #{School.unscoped.find(:all).last.id}"
  end

  def bump_ids
    puts "Adding a course, section and enrollment then deleting them all"
    # add a course, section and enrollment then archive them;
    # this will make the ids for those models diff from the UA ids for
    # future instances
    # there are archived courses, sections and enrollments
    # so use one of those to copy
    puts "Course last id #{Course.unscoped.find(:all).last.id}"
    puts "Section last id #{Section.unscoped.find(:all).last.id}"
    puts "Enrollment last id #{Enrollment.unscoped.find(:all).last.id}"
    orig_course = Course.unscoped.find(:all).first
    copy_course = orig_course.dup
    # do this or the delete won't work
    copy_course.is_archived = false
    copy_course.save!(validate: false)
    orig_section = Section.unscoped.find(:all).first
    copy_section = orig_section.dup
    copy_section.is_archived = false
    copy_section.save!(validate: false)
    orig_enrollment = Enrollment.unscoped.find(:all).first
    copy_enrollment = orig_enrollment.dup
    copy_enrollment.save!(validate: false)
    # output ids for reference
    puts "Course next id #{Course.unscoped.find(:all).last.id + 1}"
    puts "Section next id #{Section.unscoped.find(:all).last.id + 1}"
    puts "Enrollment next id #{Enrollment.unscoped.find(:all).last.id + 1}"
    copy_course.delete
    copy_section.delete
    copy_enrollment.delete
  end

end
