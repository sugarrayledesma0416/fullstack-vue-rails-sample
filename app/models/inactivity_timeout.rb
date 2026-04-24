class InactivityTimeout
  attr_reader :user, :school, :session

  def initialize(user:, school:, session:)
    @user = user
    @school = school
    @session = session
  end

  def seconds_before_warning
    if Rails.env.test?
      7
    elsif Rails.env.qa?
      20
    else
      100
    end
  end

  def seconds_between_checks
    if Rails.env.test?
      1
    elsif Rails.env.qa?
      10
    else
      60
    end
  end

  def enabled_in_selected_school?
    !timeout_in_selected_school.nil?
  end

  def enabled_in_any_school?
    !timeout_in_any_school.nil?
  end

  def timeout
    timeout_in_selected_school || timeout_in_any_school
  end

  # Returns the time before logging out the user for inactivity.
  def timeout_in
    if session.nil?
      # No logged in user. Returns 0 to log out the user now. This case occurs
      # when the user opened multiple tabs in a browser. I might have been logged
      # out in one tab then this method is called by another tab.
      0
    elsif enabled_in_selected_school?
      # We want to log out the user only if the current selected school is
      # configured for timeout.
      timeout - (Time.now.utc.to_i - session.last_activity_time_epoch.to_i)
    end
  end

  def update_last_activity_time(last_activity_time = nil)
    return unless session

    last_activity_time_epoch = if last_activity_time
                                 [
                                   session.last_activity_time_epoch.presence || Time.now.utc.to_i,
                                   last_activity_time
                                 ].max
                               else
                                 Time.now.utc.to_i
                               end

    session.update(last_activity_time_epoch:)
  end

  private def timeout_in_selected_school
    if session.nil? || user.blank?
      nil
    elsif school_config.present?
      if user.student?
        school_config.student_timeout
      else
        school_config.instructor_timeout
      end
    end
  end

  private def timeout_in_any_school
    if session.nil? || user.blank?
      nil
    elsif timeout_enabled_configs.present?
      if user.student?
        timeout_enabled_configs.minimum(:student_timeout)
      else
        timeout_enabled_configs.minimum(:instructor_timeout)
      end
    end
  end

  private def school_config
    return @school_config if defined? @school_config

    @school_config = if school&.school_config&.timeout_enabled?
                       school.school_config
                     elsif school&.district&.school_config&.timeout_enabled?
                       school.district.school_config
                     end
  end

  private def timeout_enabled_configs
    return @timeout_enabled_configs if defined? @timeout_enabled_configs

    @timeout_enabled_configs = if user
                                 SchoolConfig.where(
                                   school_id: school_and_district_ids,
                                   timeout_enabled: true
                                 )
                               end
  end

  private def school_and_district_ids
    @school_and_district_ids ||= user.schools.pluck(:id, :district_id).flatten.compact.uniq
  end
end
