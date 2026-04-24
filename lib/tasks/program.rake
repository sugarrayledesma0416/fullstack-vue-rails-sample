namespace :program do
  namespace :program_config do
    desc 'create program configuration records from program_settings.yml'
    task :create => :environment do
      # Allow new program config to sync to UA.
      Dangerfield::Gatekeeper.shall_pass do
        program_configs_contents =
          YAML.load_file(File.join(Rails.root, 'config', 'program_settings.yml'))

        program_configs_contents.each do |program_id, program_configs|
          puts "Creating program_config: #{program_configs} for ProgramID #{program_id}"
          application_admin = User.where(username: Role::PROGRAM_CONFIG_MANAGER).first
          creator_id = application_admin && application_admin.id
          ProgramConfig
            .where(program_id: program_id.to_s)
            .first_or_create!(datastore_json: program_configs.to_json, creator_id: creator_id.to_i)
        end
      end
    end

    desc 'disable concurrent enrollment for program'
    task :disable_ce => :environment do |task_name|
      required_args = %w[program_id manager_username]
      validator = Support::TaskValidator.new(task_name:, required_args:)
      validator.check_usage

      dry_run = validator.dry_run?
      program_id = ENV.fetch('program_id')
      manager_username = ENV.fetch('manager_username')

      # Allow new program config to sync to UA.
      Dangerfield::Gatekeeper.shall_pass do
        ConcurrentEnrollmentDisabler
          .new(program_id:, manager_username:, dry_run:)
          .disable_concurrency_with_validation
      end
    end

    class ConcurrentEnrollmentDisabler
      attr_reader :program_id, :manager_username, :dry_run

      def initialize(program_id:, manager_username:, dry_run: true)
        @program_id = program_id
        @manager_username = manager_username
        @dry_run = dry_run
      end

      def program
        @program ||= Program.find(program_id)
      end

      def program_config
        @program_config ||= ProgramConfig.currently_active(program_id.to_s)
      end

      def disable_concurrency_with_validation
        if program.enable_concurrent_enrollment?
          # 1. Build a hash like the following with our target data (current enrollments):
          # student_id => [{ :course_id, :section_id, :enrollment_id }]
          # 2. Create the list of concurrent enrollments.
          # 3. Check whether the concurrent enrollment list is empty.
          if concurrent_enrollment?
            # 4. If not empty, show the list contents.
            print_concurrent_enrollments
          else
            if dry_run
              puts 'Nothing changed because this was a dry run. Would have disabled ' \
                   "concurrent enrollment in '#{program.title}' (#{program.id}).'"
            else
              # 5. If empty, disable the setting.
              disable_ce_for_program
            end
          end
        else
          p "No changes made. This program '#{program.title}' (#{program_id}) " \
            'does not have Concurrent Enrollment enabled.'
        end
      end

      private def enrollments_per_student
        enrollments = Enrollment.arel_table
        courses = Course.arel_table
        sections = Section.arel_table

        sql_query = enrollments
                    .join(sections).on(enrollments[:section_id].eq(sections[:id]))
                    .join(courses).on(sections[:course_id].eq(courses[:id]))
                    .where(
                      courses[:program_id].eq(program.id)
                      .and(enrollments[:state].eq('enrolled'))
                    )
                    .project(
                      enrollments[:user_id],
                      enrollments[:id].as('enrollment_id'),
                      enrollments[:section_id],
                      sections[:course_id]
                    ).to_sql

        result = ActiveRecord::Base.connection.exec_query(sql_query).to_a
        result.group_by { |enrollment| enrollment['user_id'] }.transform_values do |enroll|
          enroll.map { |e| e.except('user_id') }
        end
      end

      private def disable_ce_for_program
        manager = User.joins(:roles)
                      .find_by(
                        username: manager_username,
                        roles: { name: Role::PROGRAM_CONFIG_MANAGER }
                      )
        if manager
          program_config.datastore_json[:enable_concurrent_enrollment] = false
          begin
            new_prog_config = ProgramConfig.create!(
              program_id: program.id,
              datastore_json: program_config.datastore_json,
              creator_id: manager.id
            )
            if new_prog_config.persisted?
              p "Concurrent enrollment was disabled in '#{program.title}' (#{program.id}) successfully."
            end
          rescue ActiveRecord::RecordInvalid => e
            p e.record.errors
          end
        else
          p "ERROR: The user #{manager_username} is not an authorized program configuration manager."
        end
      end

      private def concurrent_enrollments
        @concurrent_enrollments ||=
          enrollments_per_student.select { |_student_id, values| values.size > 1 }
      end

      private def concurrent_enrollment?
        concurrent_enrollments.any?
      end

      private def print_concurrent_enrollments
        print "\n"
        print 'Could not disable concurrent enrollment functionality because concurrent ' \
              "enrollments already exist.\n"
        p "Concurrent enrollments as of #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')} " \
          'are listed below. Please provide this information to the person requesting ' \
          'the change to help them decide how to proceed.'
        p "=== Program information | #{program.title} | #{program.id} ==="
        print "==============================================================\n"
        print "user_id, course_id, section_id, enrollment_id\n"
        concurrent_enrollments.each do |student_id, enrollments|
          enrollments.each do |enrollment|
            print "#{student_id}, "
            print "#{enrollment['course_id']}, "
            print "#{enrollment['section_id']}, "
            print "#{enrollment['enrollment_id']}\n"
          end
        end
      end
    end
  end
end
