module Lti
  class CourseSectionCreator
    include TimeHandler
    include EventTracking

    attr_accessor :context_id, :data, :errors, :program_id, :section, :user

    DEFAULT_COURSE_DATE = '%<year>s-07-31'.freeze

    def initialize(input_params, current_user, program_id)
      self.data = input_params
      self.user = current_user
      self.program_id = program_id
      self.errors = {}
    end

    def process
      if active_section
        update_course_name
      elsif archived_section_exists?
        errors[:save] = 'Unable to create a new section for LMS context because ' \
                        'the previous section was not successfully deleted.'
      else
        create_course_and_section
      end

      if course_and_section_valid?
        check_and_associate_co_instructor
        Maestro::User.ensure_instructor_access_matches_site_license(
          user.guid,
          [ data[:school_guid] ]
        )
      end
    end

    def create_course_and_section
      with_lti_event_tracking('Create Course and Section', tracking_data) do |event|
        ActiveRecord::Base.transaction do
          course = Course.create!(new_course_params)
          @section = Section.create!(new_section_params(course))
        end
        event.section = @section
      end
      CourseLicenseCreatorWorker.perform_in(
        3.seconds,
        @section.course.guid,
        course_options.available_course_package_ids
      )
    rescue ActiveRecord::ActiveRecordError => e
      errors[:save] = "Either Course or Section failed creation #{e.message}"
    end

    def success
      errors.empty? && active_section
    end

    def check_and_associate_co_instructor
      return if active_section.course.owner_id == user.id

      unless active_section.section_instructors.exists?(role: SectionInstructor::RESPONSIBLE_ROLES.values,
                                                        user_id: user.id)
        section_instructor = active_section.section_instructors.new(
          role: SectionInstructor::RESPONSIBLE_ROLES[:co_instructor],
          user_id: user.id
        )
        if section_instructor.save
          # get the instructor the proper user licenses for
          # all programs on the site license for this school
          Maestro::User.ensure_instructor_access_matches_site_license(user.guid, [active_section.course.school.guid])
        else
          errors[:section_instructor] = "Co-instructor could not be created: #{section_instructor.errors.full_messages.join(',')}"
        end
      end
    end

    private def program
      @program ||= Program.find(program_id)
    end

    private def active_section
      return @section if defined? @section

      @section = linked_context&.section
    end

    # Checks if an archived section exists based on the provided section GUID,
    # which will only be passed if there is an linked active section in UA.
    #
    # @return [Boolean] true if an archived section with the given GUID exists,
    #                   false otherwise.
    private def archived_section_exists?
      section_guid.present? && Section.unscoped.exists?(guid: section_guid)
    end

    private def section_guid
      @section_guid if defined? @section_guid

      @section_guid = data[:section_guid]
    end

    private def context_id
      @context_id ||= data[:context_id]
    end

    private def platform
      @platform ||= Lti::Platform.find_by(guid: data[:lti_platform_guid])
    end

    private def tracking_data
      { platform: platform, user: user }
    end

    private def update_course_name
      course = section.course
      unless course.update(name: course_section_name)
        errors[:save] = "Course with guid: #{course.guid} update failed #{course.errors}"
      end
    end

    private def linked_context
      return @linked_context if defined? @linked_context

      @linked_context = Lti::ContextLink.where(context_id: context_id,
                                               lti_platform_id: platform.id).first
    end

    # Title is preferred over label for a better user experience.
    # Canvas sends the course name in the title element and the course code in the label element.
    # Schoology sends the course name appended with section name in the title element and sends the
    # context id in both the id element and the label element.
    # Both title and label are optional parameters, so the fallback is context_id (required).
    private def course_section_name
      @course_section_name ||=
        if data[:context_title].present?
          data[:context_title]
        elsif data[:context_label].present?
          data[:context_label]
        else
          context_id
        end
    end

    private def school
      @school ||= School.find_by(guid: data[:school_guid])
    end

    private def course_start_date
      @course_start_date ||=
      if data[:course_start_date].present?
        Time.zone.parse(data[:course_start_date])
      else
        Time.zone.now
      end
    end

    # If no course end date comes to us from the LMS, then we
    # will fall back to using the logic that was a Product decision
    # for Common Cartridge but is useful here. For those cases where we get
    # the end date, we can set it from that value IFF end date is after start date.
    # otherwise we need to set it using this method.
    # Course end date: if start date month is after July, we will use July 31st
    # of the following year; else we will use July 31st of the current year.
    # Instructor can edit the dates at a later time.
    private def course_end_date
      if data[:course_end_date].blank? || data[:course_end_date] <= course_start_date
        if course_start_date.month < 7
          format(DEFAULT_COURSE_DATE, year: Time.zone.now.year)
        else
          format(DEFAULT_COURSE_DATE, year: Time.zone.now.year + 1)
        end
      else
        Time.zone.parse(data[:course_end_date])
      end
    end

    private def course_options
      @course_options ||= CourseOptions.new(user, nil, program)
    end

    private def new_course_params
      attrs = {
        program_id: program.id,
        first_unit_id: program.units.first.id,
        last_unit_id: program.units.last.id,
        owner_id: user.id,
        name: course_section_name,
        draft: false,
        school_id: school&.id,
        start_date: course_start_date,
        end_date: course_end_date,
        validate_categories: true,
        allow_individual_assign: true,
        categories_attributes: [course_options.basic_category],
        standard_set_ids: program.supported_standard_set_ids,
        course_config_json: {
          setup_method: '',
          supersite_jr: program.supersite_junior?,
          express_course_copied: '',
          course_copied_id: '',
          learning_track: '',
          streamlined_rostering_setup: 'LTI-A-R'
        }.to_json
      }.tap do |memo|
        memo[:chat_level] = 'disabled' if school&.has_chat_support_disabled?
      end

      Course.default_values.merge(attrs)
    end

    private def new_section_params(course)
      {
        name: course_section_name,
        instructor_id: user.id,
        time_zone: user.time_zone || Time.zone.name,
        due_time: set_time_from_params('11', '59', 'PM'),
        open_to_students: false,
        course: course,
        section_instructors_attributes: [
          {
            user_id: user.id,
            role: 'Instructor'
          }
        ]
      }
    end

    private def course_and_section_valid?
      errors[:save].blank?
    end
  end
end
