module OneRoster
  class UnlinkedResource
    include StatsProcessor

    attr_accessor :sections, :user

    def initialize(sections:, user:)
      self.sections = sections
      self.user = user
    end

    def log_sections_without_school
      sections_with_missing_school = find_sections_missing_school

      if sections_with_missing_school.present?
        data = format_info(sections: sections_with_missing_school)
        dispatch(payload: data,
                 stats_index: 'ra-classes-missing-school-log',
                 stats_type: :warning_log)
      end
    end

    private def find_sections_missing_school
      return [] unless sections

      sections.select do |section|
        section['school'].blank?
      end
    end

    private def format_info(sections:)
      school_name = user.one_roster_linked_user.school.name
      user_info = {
        guid: user.guid,
        first_name: user.first_name,
        last_name: user.last_name
      }

      {
        payload: sections.map do |section|
          {
            school_name: school_name,
            class_id: section['sourced_id'],
            course_id: section['course_sourced_id'],
            course_name: section['course_title'],
            instructor: user_info
          }
        end
      }
    end
  end
end
