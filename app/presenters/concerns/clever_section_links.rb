module CleverSectionLinks
  extend ActiveSupport::Concern

  # clever_section_links returns a hash mapping
  # VHL section guids to clever rostering information.
  # example:
  # section_a is a non clever rostering section
  # section_b is a clever rostering section:
  # {
  #   section_a.guid: {
  #     'linked' => 'false', # default value. True only if API call confirms it is clever.
  #   },
  #   section_b.guid: {
  #     # values here are established via call to clever api
  #     'clever_section_name' => 'expected name',
  #     'error' => false,
  #     'linked' => true
  #   }
  # }

  def clever_section_links
    return @clever_section_links if defined?(@clever_section_links)

    section_defaults =
      focused_course_sections_for_instructor.each_with_object({}) do |section, memo|
        memo[section.guid] = { 'linked' => false }
      end

    @clever_section_links = if instructor.clever?
                              section_defaults.merge(rostering_section_info)
                            else
                              section_defaults
                            end
  end

  private def rostering_section_info
    # find clever sections associated with the focused course
    rostering_sections =
      focused_course_sections_for_instructor
      .includes(course: :school)
      .select { |section| section.school.rostering? }

    return {} if rostering_sections.empty?

    # Fetch data from UA for all Clever rostering sections
    clever_rostering_section_info(rostering_sections)
  end

  private def clever_rostering_section_info(sections)
    query_string = { section_guids: sections.map(&:guid) }.to_query
    endpoint = "/api/clever/section_link/search?#{query_string}"

    ua_connection.get(endpoint).body
  end

  private def ua_connection
    @ua_connection ||=
      ConnectionHandler.connection(
        basic_auth: [
          Rails.configuration.ua_api_username,
          Rails.configuration.ua_api_password
        ],
        request_type: :json,
        uri: UA_URL
      )
  end
end
