module OneRoster
  class CourseSectionCreator
    DATE_FORMAT = '%Y-%m-%d'.freeze

    include TimeHandler

    attr_accessor :course_section_data, :program,
                  :user, :notices, :errors, :section, :school_salesforce_id
    def initialize(course_section_data, program, user)
      self.course_section_data = course_section_data
      self.program = program
      self.user = user
      self.school_salesforce_id = user.one_roster_linked_user&.school&.salesforce_id
      self.notices = []
      self.errors = []
    end

    def create_course_and_section
      Course.transaction do
        if course_data
          course = Course.new(new_course_params)
          course.validate_categories = true
          if course.save
            # To avoid a race condition when there are large batches,
            # delay this job by 3 seconds.
            CourseLicenseCreatorWorker.perform_in(
              3.seconds,
              course.guid,
              course_options.available_course_package_ids
            )

            @section = course.sections.new(new_section_params)
            if @section.save
              @notices << "Section '#{section.name}' has been created."
            else
              @errors << "Section #{section.name} could not be created:"
              @errors += section.errors.full_messages
            end
          else
            @errors << "Course #{course.name} could not be created:"
            @errors += course.errors.full_messages
          end
        end
      end
    end

    def check_and_associate_as_co_instructor
      return unless school_salesforce_id

      course_sections = roster_assistant_client.courses_for_school(school_salesforce_id)
      return unless roster_assistant_client.last_request_successful?

      course_sections.each do |course_section|
        course_section['classes'].each do |one_section|
          section = Section.joins(:one_roster_linked_section)
                           .where(one_roster_linked_sections: { course_external_id: course_section['sourced_id'],
                                                                class_external_id: one_section['sourced_id'] }).first
          if section && !section.section_instructors.where(role: SectionInstructor::RESPONSIBLE_ROLES.values,
                                                           user_id: user.id).exists?
            section.section_instructors.create(role: SectionInstructor::RESPONSIBLE_ROLES[:co_instructor],
                                               user_id: user.id)
          end
        end
      end
    end

    private def roster_assistant_courses
      @roster_assistant_courses ||= roster_assistant_client.courses_for_school(school_salesforce_id)
    end

    private def course_data
      @course_data ||= roster_assistant_courses.detect do |data|
        data['sourced_id'].to_s == course_section_data['section']['course_external_id'].to_s
      end
    end

    private def section_data
      @section_data ||= course_data['classes'].detect do |data|
        data['sourced_id'].to_s == course_section_data['section']['class_external_id'].to_s
      end
    end

    private def course_options
      @course_options ||= CourseOptions.new(user, nil, program)
    end

    private def new_course_params
      Course.default_values.merge(
        program_id: program.id,
        first_unit_id: program.units.first.id,
        last_unit_id: program.units.last.id,
        owner_id: user.id,
        name: course_data['title'],
        draft: false,
        school_id: school.id,
        start_date: string_to_date(course_section_data['section']['start_date']),
        end_date: string_to_date(course_section_data['section']['end_date']),
        categories_attributes: [course_options.basic_category],
        standard_set_ids: program.supported_standard_set_ids,
        course_config_json: {
          setup_method: '',
          supersite_jr: program.supersite_junior?,
          express_course_copied: '',
          course_copied_id: '',
          learning_track: '',
          streamlined_rostering_setup: 'RA'
        }.to_json
      ).tap do |memo|
        memo[:chat_level] = 'disabled' if school.has_chat_support_disabled?
      end
    end

    private def school
      @school ||= School.find_by(salesforce_id: course_section_data['section']['salesforce_id'])
    end

    private def oneroster_linked_section_attributes
      {
        class_external_id: section_data['sourced_id'],
        course_external_id: course_data['sourced_id'],
        academic_session: section_data['academic_sessions'].present? ? section_data['academic_sessions'] : nil,
        school_id: user.one_roster_linked_user.school_id
      }
    end

    private def new_section_params
      {
        name: section_data['title'],
        instructor_id: user.id,
        time_zone: user.time_zone || Time.zone.name,
        due_time: set_time_from_params('11', '59', 'PM'),
        open_to_students: false,
        section_instructors_attributes: [
          {
            user_id: user.id,
            role: 'Instructor'
          }
        ],
        one_roster_linked_section_attributes: oneroster_linked_section_attributes
      }
    end

    private def roster_assistant_client
      @roster_assistant_client ||= OneRoster::Client.new(user.one_roster_linked_user.external_username)
    end

    private def string_to_date(date_string)
      Date.strptime(date_string, DATE_FORMAT) if date_string.present?
    end
  end
end
