module OneRoster
  class CoursesPresenter
    attr_accessor :instructor

    delegate :last_request_errors,
             :last_request_status,
             :last_request_successful?,
             :school_inactive?,
             to: :roster_assistant_client, prefix: :client

    def initialize(instructor)
      self.instructor = instructor
    end

    def roster_assistant_sections_group_by_status
      ra_courses = roster_assistant_courses
      if client_last_request_successful?
        ra_courses.each_with_object({'created_sections' => [], 'available_sections' => []}) do |course_data, memo|
          populate_section_data(course_data, course_data['classes'], memo)
        end
      else
        {}
      end
    end

    private def roster_assistant_courses
      roster_assistant_client.courses_for_school(main_school.salesforce_id)
    end

    private def section_exists?(section_identifier)
      existing_section_identifiers.key?(section_identifier)
    end

    private def start_date_for(section_identifier, roster_assistant_dates)
      if section_exists?(section_identifier)
        existing_section_identifiers[section_identifier].course.start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      elsif roster_assistant_dates.present?
        roster_assistant_dates.first['start_date'].to_time.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      end
    end

    private def end_date_for(section_identifier, roster_assistant_dates)
      if section_exists?(section_identifier)
        existing_section_identifiers[section_identifier].course.end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      elsif roster_assistant_dates.present?
        roster_assistant_dates.first['end_date'].to_time.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
      end
    end

    private def populate_section_data(course_data, classes_array, course_memo)
      classes_array.each do |section_data|
        section_data['course_title'] = course_data['title']
        section_data['course_sourced_id'] = course_data['sourced_id']
        section_data['section_identifier'] = OneRoster::LinkedSection.build_identifier(course_data['sourced_id'],
                                                                                       section_data['sourced_id'])
        section_data['m3_section'] = existing_section_identifiers[section_data['section_identifier']]
        section_data['start_date'] = start_date_for(section_data['section_identifier'],
                                                    section_data['academic_sessions'])
        section_data['end_date'] = end_date_for(section_data['section_identifier'],
                                                section_data['academic_sessions'])
        section_data['school'] = school_lookup(section_data.fetch('school_salesforce_id', nil))
        if section_data['m3_section']
          course_memo['created_sections'] << section_data
        else
          course_memo['available_sections'] << section_data
        end
      end
    end

    private def school_lookup(school_salesforce_id)
      (@school_lookup ||= {})[school_salesforce_id] ||= if school_salesforce_id.present?
                                                          School.find_by(salesforce_id: school_salesforce_id)
                                                        end
    end

    private def main_school
      instructor.one_roster_linked_user.school
    end

    private def existing_section_identifiers
      @existing_section_identifiers ||= instructor.sections.joins(:one_roster_linked_section)
                                                  .each_with_object({}) do |section, memo|
        identifier = section.one_roster_linked_section.identifier
        memo.merge!(identifier)
      end
    end

    private def roster_assistant_client
      @roster_assistant_client ||= OneRoster::Client.new(instructor.one_roster_linked_user.external_username)
    end
  end
end
