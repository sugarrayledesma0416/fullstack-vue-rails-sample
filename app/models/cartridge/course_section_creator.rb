module Cartridge
  class CourseSectionCreator
    include TimeHandler

    attr_accessor :data, :user, :resource_link, :errors, :section
    ENROLLMENT_ERROR_TO_SKIP = "You don't have all of the required access to complete this course.".freeze
    LEGACY_LTI_VERSION = '1.1.0'.freeze
    # 99.5% of cartridge sections were created in UA within 3 seconds of
    # M3 section creation (stat from Mar 2021 - Sep 2025 data)
    MAX_SECONDS_TO_DELAY_ENROLLMENT = 3

    def initialize(data, current_user, resource_link)
      self.data = data
      self.user = current_user
      self.resource_link = resource_link
      self.errors = {}
    end

    def course_and_section_valid?
      errors[:section].blank? && errors[:course].blank?
    end

    def process
      if archived_course?
        set_archived_course_error
        return
      end

      create_course_and_section unless existing_section
      if existing_section
        check_and_associate_co_instructor if user.instructor?
        legacy_launch? ? update_lis_outcome_service_url : update_line_items_url
      end

      return unless course_and_section_valid?

      if user.student?
        create_or_update_score_destination
        wait_for_new_section_sync
        student_enroller
      elsif user.instructor?
        Maestro::User.ensure_instructor_access_matches_site_license(
          user.guid,
          [user.cartridge_user_link.school.guid]
        )
      end
    end

    def create_course_and_section
      Course.transaction do
        course = Course.new(new_course_params)
        if course.save
          CourseLicenseCreatorWorker.perform_in(
            3.seconds,
            course.guid,
            course_options.available_course_package_ids
          )

          @section = course.sections.new(new_section_params(course.id))
          unless @section.save
            errors[:section] = "Section #{@section.name} could not be created: #{@section.errors.full_messages.join(',')}"
          end
        else
          errors[:course] = "Course #{course.name} could not be created: #{course.errors.full_messages.join(',')}"
        end
      end
    end

    def check_and_associate_co_instructor
      return if existing_section.course.owner_id == user.id

      unless existing_section.section_instructors.exists?(role: SectionInstructor::RESPONSIBLE_ROLES.values,
                                                          user_id: user.id)
        section_instructor = existing_section.section_instructors.new(
          role: SectionInstructor::RESPONSIBLE_ROLES[:co_instructor],
          user_id: user.id
        )
        unless section_instructor.save
          errors[:section_instructor] = "Co-instructor could not be created: #{section_instructor.errors.full_messages.join(',')}"
        end
      end
    end

    def create_or_update_score_destination
      return unless activity_is_assigned?

      destination = {
        user: user,
        section: existing_section,
        activity: activity
      }
      if legacy_launch?
        Cartridge::ScoreDestination.add_or_update(
          **destination.merge(lis_result_sourcedid: data[:lis_result_sourcedid])
        )
      else
        Cartridge::LineItemDestination.add_or_update(
          **destination.merge(line_item_url: data[:line_item_url])
        )
      end

      add_assignment
    end

    def student_enroller
      # enroll if the student is not in the section and
      # re-enroll if the student does not have sufficient access.
      return if existing_enrollment.where(sufficient_access: true).exists?

      result = EnrollmentEngine::Enroller.new(
        user,
        existing_section,
        enroll_by: EnrollmentEngine::ENROLL_BY_COMMON_CARTRIDGE
      ).enroll
      # We want the activity controller to process the access to the activity,
      # so we skip the insuficient access error.
      enrollment_errors = result.errors.full_messages - [ENROLLMENT_ERROR_TO_SKIP]
      if enrollment_errors.present?
        errors[:enrollment] = "Student guid: #{enrollment_errors.join(',')}"
      else
        existing_enrollment_guid = existing_enrollment.pluck(:guid)
        enrollments_guids = []
        Retryable.retryable(tries: 5, sleep: 0.5, on: MaestroCore::ResourceNotFound) do
          enrollments_guids = Maestro::Enrollment.check_licenses(
            existing_enrollment_guid
          )['enrollment_guids']
        end
        unless enrollments_guids.empty?
          existing_enrollment.where(guid: enrollments_guids).update(sufficient_access: true)
        end
      end
    end

    def success
      return false unless errors.empty? && existing_section

      # Try to verify course licenses have been created; waiting up to 10 seconds.
      # 93% of cartridge-linked course licenses are created within 10 seconds
      # of course creation (stat from Jan 2025 - Sep 2025 data)
      result = 20.times do
        break true if has_course_licenses?

        sleep(0.5)
      end
      if result == true
        true
      else
        errors[:course_license] = "The Course Licenses for #{existing_section.course.name} have not been created."
        false
      end
    rescue MaestroCore::ConnectionError
      false
    end

    private def has_course_licenses?
      Maestro::CourseLicense.all(existing_section.course.guid).count > 0
    end

    # Waits briefly to allow time for a new section to be synchronized in UA.
    # If the existing section was created within the last X seconds, sleeps
    # until X seconds have passed since its creation. Otherwise, does not sleep.
    #
    # This reduces the risk that the enrollment process fails to find the new
    # section in UA when trying to grant site license seats.
    private def wait_for_new_section_sync
      seconds_since_creation = Time.zone.now - existing_section.created_at
      return if seconds_since_creation >= MAX_SECONDS_TO_DELAY_ENROLLMENT

      sleep(MAX_SECONDS_TO_DELAY_ENROLLMENT - seconds_since_creation)
    end

    private def existing_enrollment
      Enrollment.active.where(section: existing_section, user: user)
    end

    private def update_lis_outcome_service_url
      return if data[:lis_outcome_service_url].blank? ||
                existing_section.cartridge_course_context_detail.lis_outcome_service_url == \
                data[:lis_outcome_service_url]

      course_context_detail.update_lis_outcome_service_url(data[:lis_outcome_service_url])
    end

    private def update_line_items_url
      return if data[:line_items_url].blank? ||
                existing_section.cartridge_course_context_detail.line_items_url == \
                data[:line_items_url]

      course_context_detail.update_line_items_url(data[:line_items_url])
    end

    private def course_section_name
      "course_section_#{data[:context_id]}"
    end

    # Product decision. Course end date: if creation month is after July, we will use July 31st
    # of the following year; else we will use July 31st of the current year
    private def course_end_date
      if Time.zone.now.month < 7
        "#{Time.zone.now.year}-07-31"
      else
        "#{Time.zone.now.year + 1}-07-31"
      end
    end

    private def course_options
      @course_options ||= CourseOptions.new(contexts_owner.user, nil, program)
    end

    private def new_course_params
      Course.default_values.merge(
        program_id: program.id,
        first_unit_id: program.units.first.id,
        last_unit_id: program.units.last.id,
        owner_id: contexts_owner.user_id,
        name: data[:context_title] || course_section_name,
        draft: false,
        school_id: contexts_owner.school_id,
        start_date: Time.zone.now,
        end_date: course_end_date,
        validate_categories: true,
        categories_attributes: [course_options.basic_category]
      ).tap do |memo|
        memo[:chat_level] = 'disabled' if school&.has_chat_support_disabled?
      end
    end

    private def cartridge_course_context_detail_attributes(course_id)
      {
        launch_presentation_return_url: data[:launch_presentation_return_url],
        lms_context_id: data[:context_id],
        lis_outcome_service_url: data[:lis_outcome_service_url],
        line_items_url: data[:line_items_url],
        course_id: course_id,
        school_id: contexts_owner.school_id,
        program_id: program.id
      }
    end

    private def new_section_params(course_id)
      {
        name: data[:context_title] || course_section_name,
        instructor_id: contexts_owner.user_id,
        time_zone: contexts_owner.user.time_zone || Time.zone.name,
        due_time: set_time_from_params('11', '59', 'PM'),
        open_to_students: false,
        section_instructors_attributes: [
          {
            user_id: contexts_owner.user_id,
            role: 'Instructor'
          }
        ],
        cartridge_course_context_detail_attributes: cartridge_course_context_detail_attributes(course_id)
      }
    end

    private def cartridge_consumer
      Cartridge::Consumer.find_by!(guid: data[:consumer_guid])
    end

    private def school
      legacy_launch? ? cartridge_consumer.school : lti_platform.school
    end

    private def contexts_owner
      @contexts_owner ||= Cartridge::UserLink.find_by(
        school_id: school.id,
        contexts_owner: true
      )
    end

    private def lti_platform
      Lti::Platform.find_by!(guid: data[:platform_guid])
    end

    private def lti_version
      @lti_version ||= data[:lti_version]
    end

    private def program
      @program ||= case resource_link.resource_type
                   when  'activity'
                     Program.joins(units: [lessons: :activities])
                            .find_by(activities: { id: resource_link.resource_id })
                   when  'resource'
                     Program.joins(:resources)
                            .find_by(resources: { id: resource_link.resource_id })
                   when  'instructor_vtext', 'student_vtext'
                     Program.find(resource_link.resource_id)
                   end
    end

    private def existing_section
      return @section if defined? @section

      @section = course_context_detail&.section
    end

    private def course_context_detail
      return @course_context_detail if defined? @course_context_detail

      # need to lookup within the school and for the same program;
      # should only ever find 1
      @course_context_detail = Cartridge::CourseContextDetail.unscoped.find_by(
        lms_context_id: data[:context_id], school_id: school.id, program_id: program.id
      )
    end

    private def activity_is_assigned?
      return false unless resource_link.resource_type == 'activity'

      if legacy_launch?
        data[:lis_outcome_service_url].present? && data[:lis_result_sourcedid].present?
      else
        data[:line_items_url].present? && data[:line_item_url].present?
      end
    end

    # if this is an assigned activity then add an assignment
    # if none exists. Use the course end date as the due date.
    # Immaterial what we use, it just needs to be on or before
    # the course end_date, Actual assignment and due date are controlled
    # by the LMS.
    private def add_assignment
      assignment = Assignment.find_with_course_category(section, activity)
      unless assignment
        assignment_params = { category_id: section.course.categories.first.id,
                              section: section,
                              assignable: activity,
                              due_date: section.course.end_date }

        Assignment.create!(assignment_params)
      end
    end

    private def activity
      @activity ||= Activity.find(resource_link.resource_id)
    end

    private def archived_course?
      course_context_detail&.is_archived?
    end

    private def set_archived_course_error
      errors[:closed_course] = 'The course you are trying to access has been closed in VHLCentral'\
                               ' and is no longer available.'
    end

    private def legacy_launch?
      lti_version == LEGACY_LTI_VERSION
    end
  end
end
