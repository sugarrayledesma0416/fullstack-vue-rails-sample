class PasswordAttemptValidator < Struct.new(:current_user, :section_id, :activity_id, :assessment_password)
  def attempt
    # This is similar to Attempt#active_attempt.
    @attempt ||= Attempt.by_student_section_and_activity(current_user, Section.find(section_id), Activity.find(activity_id)).active.first
  end
  private :attempt

  def stored_password
    @stored_password ||= Assignment
      .by_assignable_id(activity_id)
      .by_section(section_id)
      .not_external
      .first
      .assigned_assessment_detail
      .password
  end
  private :stored_password

  def correct?
    stored_password.try(:strip) == assessment_password.try(:strip)
  end

  def log_password_attempt
    if attempt && attempt.id > 0
      PasswordAttempt.create(
        :attempt_id => attempt.id,
        :correct => correct?,
        :password => assessment_password)
    end
  end
end
