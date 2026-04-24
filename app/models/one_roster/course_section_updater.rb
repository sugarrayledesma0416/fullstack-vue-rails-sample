module OneRoster
  class CourseSectionUpdater
    # retrieves latest classes info for specified course from RosterAssistant;
    # update both the course and the section for each class if they exist;
    # if any of the classes no longer exist in RA, archived the section and the course
    # and delete the LinkedSection
    attr_accessor :course_external_id, :school, :errors
    DATE_FORMAT = '%Y-%m-%d'.freeze

    def initialize(school_id, course_external_id)
      self.school = School.find(school_id)
      self.course_external_id = course_external_id
      self.errors = []
    end

    def update
      classes = roster_assistant_client.classes_for_course(school.salesforce_id, course_external_id)
      existing_linked_classes = OneRoster::LinkedSection.where(course_external_id: course_external_id, school_id: school.id)
      existing_linked_classes_ids = existing_linked_classes.pluck(:class_external_id)
      linked_sections_found = []
      if classes.present?
        # ignore any new classes in the RA data
        classes_data = classes.reject { |class_data| existing_linked_classes_ids.exclude?(class_data['sourced_id']) }
        # loop through the classes for this course
        classes_data.each do |one_roster_class|
          # find the LinkedSection to update
          linked_section = existing_linked_classes.select {|item| item.class_external_id == one_roster_class['sourced_id']  }
          update_section_and_course(linked_section.first.section, one_roster_class)
          linked_sections_found << linked_section.first
        end
      else
        Rails.logger.info "CourseSectionUpdater no classes retrieved from RosterAssistant for course: #{course_external_id} school: #{school.salesforce_id}"
      end
      # any ids left after we remove the found ones are the ones that
      # have been deleted from RA and need to be archived
      to_be_deleted = existing_linked_classes - linked_sections_found
      archive_deleted_classes(to_be_deleted)
      update_enrollments(linked_sections_found) if linked_sections_found.present?
    end

    private def update_section_and_course(section, one_roster_class)
      return if section.course.closed?

      section_new_attributes = section_update_attributes(
        section,
        one_roster_class
      )
      course_new_attributes = course_update_attributes(
        section.course,
        one_roster_class
      )

      section.update(section_new_attributes) unless section_new_attributes.empty?
      section.course.update(course_new_attributes) unless course_new_attributes.empty?
    end

    private def section_update_attributes(section, one_roster_class)
      {}.tap do |memo|
        if section.name != one_roster_class['title']
          memo[:name] = one_roster_class['title']
        end
      end
    end

    private def course_update_attributes(course, one_roster_class)
      {}.tap do |memo|
        if course.name != one_roster_class['course_title']
          memo[:name] = one_roster_class['course_title']
        end
        if one_roster_class['academic_sessions'].present?
          ra_start_date = string_to_date(
            one_roster_class['academic_sessions'][0]['start_date']
          )
          memo[:start_date] = ra_start_date if course.start_date != ra_start_date

          ra_end_date = string_to_date(
            one_roster_class['academic_sessions'][0]['end_date']
          )
          memo[:end_date] = ra_end_date if course.end_date != ra_end_date
        end
      end
    end

    # archiving the section will cause the enrollments to be dropped;
    # then the course needs to be archived and the linked_section destroyed
    private def archive_deleted_classes(to_be_deleted)
      to_be_deleted.each do |linked_section|
        Rails.logger.info "CourseSectionUpdater archive OneRoster::LinkedSection course: #{linked_section.section.course.id} section:#{linked_section.section.id}}"
        course = linked_section.section.course
        next if course && (course.end_date <= 7.days.from_now)

        section = linked_section.section
        # ensure that the linked section is not orphaned
        if section.present?
          Course.transaction do
            section.archive
            errors << section.errors.full_messages if section.errors.present?
            course.archive
            errors << course.errors.full_messages if course.errors.present?
          end
        else # remove the orphan
          linked_section.destroy
        end
      end
    end

    # tell UA to make necessary changes to the
    # enrollments in these linked sections
    private def update_enrollments(linked_sections)
      new_sections = linked_sections.map do |linked_section|
        {
          section_guid: linked_section.section.guid,
          external_class_id: linked_section.class_external_id
        }
      end
      begin
        Ua::OneRosterEnrollments.create(sections: new_sections)
      rescue ActiveResource::ServerError => e
        # problem contacting UA
        Rails.logger.warn "UA returned bad response: #{e.message} during enrollments update for #{new_sections}"
      end
    end

    private def roster_assistant_client
      @roster_assistant_client ||= OneRoster::Client.new
    end

    private def string_to_date(date_string)
      Date.strptime(date_string, DATE_FORMAT) if date_string.present?
    end
  end
end
