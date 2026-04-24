# Helper methods for course ownership transfer
# between instructors.
module CourseOwnerUtilities
  ALLOWED_TYPES_FOR_TRANSFER = ['Clever', 'Roster Assistant', 'LTI Rostering'].to_sentence(
    last_word_connector: ', or ',
    two_words_connector: ' or '
  ).freeze

  def allows_rostering_course_transfer?
    clever_instructor? || ra_instructor? || lti_rostering_instructor?
  end

  def other_instructor_same_type?(other_instructor)
    clever_instructor? && other_instructor.clever_instructor? ||
      ra_instructor? && other_instructor.ra_instructor? ||
      lti_rostering_instructor? && other_instructor.lti_rostering_instructor?
  end

  def instructor_type
    if clever_instructor?
      'Clever'
    elsif ra_instructor?
      'Roster Assistant'
    elsif lti_rostering_instructor?
      'LTI Rostering'
    end
  end

  # need to filter out instructors
  # whose district transitioned to LTI-A-R;
  # those instructors will return true for both
  # one_roster? AND lti_rostering_instructor?
  def ra_instructor?
    instructor? && one_roster? && !lti_rostering_instructor?
  end

  def lti_rostering_instructor?
    instructor? && lti_rostering?
  end

  def same_type_instructors_in_school
    other_instructors_in_school = if clever_instructor?
                                    Instructor.where(
                                        ['users.email LIKE ?',
                                         "%#{User::CLEVER_USERS_FAKE_EMAIL_DOMAIN}"]
                                    ).where
                                      .missing(:lti_user_link)
                                      .joins(:schools)
                                      .by_school(*schools)
                                      .uniq
                                  elsif ra_instructor?
                                    Instructor.where
                                      .missing(:lti_user_link)
                                      .joins(:one_roster_linked_user)
                                      .joins(:schools)
                                      .by_school(*schools)
                                      .uniq
                                  elsif lti_rostering_instructor?
                                    Instructor.where(
                                      User::LTI_USERS_FAKE_EMAIL_DOMAINS.map do |email_domain|
                                        "users.email LIKE '%#{email_domain}'"
                                      end.join(' OR ')
                                    )
                                      .joins(:schools)
                                      .by_school(*schools)
                                      .uniq
                                      .select { |instructor| instructor.lti_rostering_user_link.present? }
                                  else
                                    []
                                  end
    (other_instructors_in_school - [self]).sort_by(&:first_name)
  end
end
