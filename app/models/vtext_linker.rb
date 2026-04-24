class VtextLinker
  attr_accessor :activity, :program, :program_settings, :session, :user
  attr_writer :section

  delegate :vtext_icon, :vtext_description, to: :program_settings

  def initialize(program, user, activity = nil, section: nil, session: {})
    self.activity = activity
    self.program  = program
    self.section = section
    self.session = session
    self.user = user
    self.program_settings = ProgramSettings.new(program)
  end

  def vtext_link
    activity && activity_vtext_url || program_settings.vtext_link
  end

  def activity_linkable?(access_guardian)
    activity_page.present? &&
      activity_vtext_url.present? &&
      has_vtext_access?(access_guardian)
  end

  def menu_linkable?
    program_has_vtext?
  end

  def link
    if (activity && activity_vtext_url.blank?) || menu_link.blank?
      ''
    else
      [
        menu_link,
        activity && "&page=#{first_page}"
      ].compact.join
    end
  end

  def link_label
    program_settings.vtext_label.presence || program_settings.vtext&.type || 'vText'
  end

  def menu_link
    (vtext_link && vtext_link + "?rid=#{section.id}") || ''
  end

  private def activity_page
    return @activity_page if defined? @activity_page

    @activity_page = (link_vtext_page || activity.page)
  end

  private def activity_vtext_url
    return @activity_vtext_url if defined? @activity_vtext_url

    @activity_vtext_url = if vtext_number == 1
                            program_settings.vtext_link
                          elsif vtext_number == 2
                            program_settings.teacher_vtext_link
                          else
                            additional_entry&.url
                          end
  end

  private def additional_vtext_entries
    program_settings.content_menu_additional_entries
  end

  private def additional_entry
    return @additional_entry if defined? @additional_entry

    @additional_entry = additional_vtext_entries[vtext_number - 3]
  end

  private def first_page
    link_vtext_first_page || activity.first_page
  end

  private def has_vtext_access?(access_guardian)
    # The access guardian should do the check using the default program
    # if vtext_number is 1 or 2 (the default student and instructor vtexts
    # respectively) or if the vtext is one of the additional entries (with
    # vtext number 3 or higher) and has a custom program id.
    program_id = additional_entry.program_id if vtext_number > 2
    access_guardian.has_vtext?(program_id)
  end

  # When the page specifies an alternate vtext, returns the first page number
  # in a dash-delimited page range, without the specifier for the vtext number.
  # e.g. if the page value is 'v3(12-34)', returns '12'.
  private def link_vtext_first_page
    return unless link_vtext_page

    if link_vtext_page.to_s =~ Activity::ALTERNATE_VTEXT_PAGE_NUMBER_REGEXP
      Regexp.last_match(1)
    else
      link_vtext_page
    end.split('-').first
  end

  # a link_vtext activity contains an embedded page number that we'll
  # want to use when generating the vtext link
  private def link_vtext_page
    return unless activity.activity_type == 'link_vtext'

    @link_vtext_page ||= activity.content_object.link_vtext.page
  end

  private def program_has_vtext?
    program_settings.has_vtext_link?
  end

  private def section
    if user.instructor?
      Section.section_zero
    elsif @section
      @section
    else
      user.current_section_in_program(program, session) || Section.section_zero
    end
  end

  # When the activity page specifies an alternate vtext, returns the vtext
  # number.
  # e.g. if the page value is 'v3(12-34)', returns 3.
  private def vtext_number
    @vtext_number ||= if activity_page.to_s =~ /v(\d+)\([^)]+\)/
                        Regexp.last_match(1).to_i
                      elsif activity_page.present?
                        1
                      end
  end
end
