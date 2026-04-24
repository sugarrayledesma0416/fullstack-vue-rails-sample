class AccessGuardian
  attr_reader :user, :program

  def initialize(user, program)
    @user = user
    @program = program
  end

  def can_access_content?(obj, lesson)
    has_accessible_license_group?(obj) && has_accessible_lesson?(lesson)
  end

  def has_accessible_lesson?(lesson)
    # add one to deal with the fact that unit ranks start at 0
    lesson.current_events? || valid_program_units.include?(lesson.unit_rank)
  end

  # obj passed to this method must respond to license_group_id
  # If alternate_program_id is specified, check for license groups for
  # that alternate program as opposed to the default program.
  def has_accessible_license_group?(obj, alternate_program_id = nil)
    accessible_license_group_ids(alternate_program_id).include?(obj.license_group_id)
  end

  # Occasionally, students have been accessing activities with urls not
  # including a program. In those instances, #has_accessible_license_group?
  # attempts to call license_group_ids on an array, resulting in a
  # NoMethodError.
  class EmptyLicenseContent
    def license_group_ids
      []
    end
  end

  def has_grace_period?
    user_licenses.any? { |ul| ul.grace_period? && !ul.expired? }
  end

  def has_unexpired_demo_access?
    demo_license && demo_license.expiration_date.to_date >= Date.today
  end

  def demo_days_remaining
    (demo_access_expiration_date.to_date - Date.today).to_i
  end

  def demo_access_expiration_date
    demo_license&.expiration_date
  end

  def ever_had_demo_access?
    demo_license.present?
  end

  def ebook_expiration_date
    ebook_license&.expiration_date
  end

  def site_functions
    @site_functions ||= user_licenses.inject({}) do |funcs, ul|
      license_group = ul.license_group
      if license_group.site_function?
        funcs[license_group.site_function_name.to_sym] = SiteFunction.new(license_group.site_function_name, license_group.id)
      end
      funcs
    end
  end

  def has_vocab_words?
    my_vocab = site_functions[:my_vocabulary]
    my_vocab && has_accessible_license_group?(my_vocab)
  end

  # Vocabulary Tools uses the same license group as My Vocabulary
  alias has_vocab_tools? has_vocab_words?

  def has_vtext?(alternate_program_id = nil)
    # Instructors should always have access to vtext.
    if user.instructor?
      true
    else
      vtext = site_functions[:vtext]
      vtext && has_accessible_license_group?(vtext, alternate_program_id)
    end
  end

  def has_ebook?
    ebook = site_functions[:eBook]
    ebook && has_accessible_license_group?(ebook)
  end

  def has_live_chat?
    live_chat = site_functions[:live_chat]
    live_chat && has_accessible_license_group?(live_chat)
  end

  def has_mobile_app?
    user_licenses.any? { |license| !license.expired? && license.practice_app? }
  end

  def has_portfolio?
    if @user.fake? && @user.is_student?
      has_portfolio_for_fake_student?
    else
      has_portfolio_access?
    end
  end

  def has_portfolio_access?
    portfolio = site_functions[:portfolio]
    portfolio && has_accessible_license_group?(portfolio)
  end

  # We limit sample student's portfolio related access based on
  # the corresponding instructor's access.
  def has_portfolio_for_fake_student?
    instructor = @user.sections.first&.instructor
    return false unless instructor

    return has_portfolio_access? if instructor == @user

    AccessGuardian.new(instructor, @program).has_portfolio?
  end

  # We don't care what permissions the user has. We want to call out premium
  # content for all instructors, so we are comparing directly to the premium
  # license ids, instead of checking the user licenses. We also don't want to
  # make another call to API to get the magic number.
  def premium_license?(license_group_id)
    premium_license_id = 23
    license_group_id && (license_group_id == premium_license_id)
  end

  def valid_program_units
    if tokenized_program_units.include?('*')
      program_units.map(&:rank)
    else
      expanded_units
    end
  end

  # Check `.present?` in case TechProd enters an empty string or a
  # string containing only whitespace in the ProgramConfig where the
  # alternate entries are defined.
  private def accessible_license_group_ids(alternate_program_id)
    if alternate_program_id.present?
      # Call .to_i because the program_id in the ProgramConfig is stored
      # as a string.
      alternate_program_licensed_content(alternate_program_id.to_i)
    else
      user_licensed_content
    end.license_group_ids
  end

  private def all_licenses
    @all_licenses ||= Maestro::UserLicense.all_for_user(user.guid)
  end

  # Performs extra Maestro::LicensedContent lookup only when necessary
  # (when a call is made to check license groups for an additional program)
  # Memoizes the results in a hash keyed off program_id.
  private def alternate_program_licensed_content(alternate_program_id)
    @content_by_program_id ||= {}
    @content_by_program_id[alternate_program_id] ||= get_licensed_content(
      user.guid, alternate_program_id
    )
  end

  private def dash_and_comma_separated_units
    dash_units, comma_units = tokenized_program_units.partition { |u| u.match(/-/) }
    expanded_dash_units = dash_units.map { |u| expand_range(u) }
    [expanded_dash_units.flatten, comma_units.map(&:to_i)]
  end

  private def demo_license
    user_licenses.detect(&:demo)
  end

  private def ebook_license
    user_licenses.detect { |ul| ul.license_group.name == 'eBook' }
  end

  private def expand_range(dash_string)
    start_num, end_num = dash_string.split('-')
    # Add 1 to account for 1-based unit counting
    end_num = program_units.last.rank + 1 if end_num == '*'
    (start_num.to_i..end_num.to_i).to_a
  end

  private def expanded_units
    dash_units, comma_units = dash_and_comma_separated_units
    # Subtract 1 from each unit number to account for 1-based counting
    # in the user interface, versus the 0-based counting in the
    # database.
    comma_units.concat(dash_units).uniq.map { |u| u - 1 }
  end

  private def get_licensed_content(user_guid, program_id)
    Maestro::LicensedContent.find_for_user_and_program(
      user_guid, program_id
    )
  end

  private def program_units
    @program_units ||= @program.units
  end

  private def tokenized_program_units
    @tokenized_program_units ||= user_licensed_content.lessons.gsub(/\s+/, '').split(',')
  end

  private def user_licensed_content
    @user_licensed_content ||= if program
                                 get_licensed_content(user.guid, program.id)
                               else
                                 EmptyLicenseContent.new
                               end
  end

  private def user_licenses
    return [] unless program

    @user_licenses ||= Maestro::UserLicense.all_for_user_and_program(
      user.guid, program.id
    )
  end
end
