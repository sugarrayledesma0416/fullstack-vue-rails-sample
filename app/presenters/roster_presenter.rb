class RosterPresenter
  include DateTimeHelper
  include UserEmailHelper
  include ApplicationHelper

  LICENSE_GROUP_NAME_REGEXP = /[\d-]/

  def initialize(section_id, program)
    @section_id = section_id
    @program = program
  end

  def student_data
    students.map do |student|
      submission = last_submissions_by_student[student.id]
      {
        name: "#{student.last_name}, #{student.first_name}",
        email: user_display_email(student),
        last_submission: {
          date: submission&.strftime('%b %d %Y') || nil,
          time: submission&.strftime('%I:%M %p') || nil
        },
        # Please keep the order of these calls as is, the reason is that we only
        # want to call student_user_licenses[] for the students that have grace periods
        # for the course. Since student_user_licenses[] retrieves all the user licenses for
        # the student and it will expensive to call it for all students in the roster.
        sufficient_access: (student.sufficient_access? &&
                            !student_user_licenses_with_grace_period?(student.guid)),
        insufficient_access_message: insufficient_access_message_for_student(student)
      }
    end
  end

  def students
    # We don't want to rely on the focus to get us the students as this page
    # appears to be part of the gradebook and the gradebook relies on the focus
    # as little as possible because of the bugs it causes.
    return @students if defined?(@students)
    # This works if you only need students actively enrolled in the section.
    # # Just needs a section id, returns a Student object with a magic extra
    # # sufficient_access method retrieved from the join table (enrollments)
    @students = Student
                .select('users.*, enrollments.sufficient_access')
                .joins(:enrollments)
                .where(enrollments: { section_id: @section_id,
                                      state: 'enrolled' })
                .group('users.id')
                .order('users.last_name')
                .includes(:enrollments)

    # You can also pass in an array of section_ids and it'll work, as long as
    # the section ids are from the same course. If the student has transferred
    # between the two sections many times, they can still have only one
    # enrollment with state 'enrolled'.
  end

  def update_sufficient_access
    students.each do |student|
      student.enrollments.each do |enrollment|
        insufficient_access = all_user_licenses_have_expired?(student.guid)

        if enrollment.sufficient_access && insufficient_access
          enrollment&.update(sufficient_access: false)
        end
      end
    end
  end

  def students_count_label
    word = pluralize_without_count(students.to_a.size, 'Student')
    "#{students.to_a.size} #{word}"
  end

  private def insufficient_access_message_for_student(student)
    insufficient_access_message = [].tap do |message|
      # The student has grace periods.
      # Please keep the order of these calls as is, the reason is that we only
      # want to call student_user_licenses[] for the students that have grace periods
      # for the course. Since student_user_licenses[] retrieves all the user licenses for
      # the student for the program and it will expensive to call it for all students in the roster.
      if user_guids_with_grace_periods.include?(student.guid) &&
         student_user_licenses[student.guid].detect(&:grace_period?)
        message << "The student grace period will expire in #{grace_period_days_remaining(student)} days"
      end

      unless student.sufficient_access?
        has_immediate_access_revocation = section_immediate_access_revokes(
          Section.where(id: @section_id).pick(:guid)
        ).include?(student.guid)
        if has_immediate_access_revocation
          message << "The student's Instant Access has been removed"
        end
        if insufficient_access_students_user_licenses[student.guid]
          has_expired_access = insufficient_access_students_user_licenses[student.guid].all?(&:expired?)
          if !has_expired_access
            # Student is missing some access.
            message << "The student doesn't have all the required access to complete the course"
            student_license_groups = insufficient_access_students_user_licenses[student.guid].reject(&:expired?).map(&:license_group)
            missing_license_group_names = course_licenses.map(&:name) - student_license_groups.map(&:name)
            missing_license_group_names = missing_license_group_names.map do |name|
              name.gsub(LICENSE_GROUP_NAME_REGEXP, '').gsub('_', ' ')
            end
            message << "Missing access: #{missing_license_group_names.uniq.join(', ')}" if missing_license_group_names.present?
          else
            # Student access has expired.
            if has_immediate_access_revocation
              message << 'They no longer have access to this program'
            else
              message << 'The student access for this program has expired'
            end
          end
        elsif !has_immediate_access_revocation
          # Student has no entitlements.
          message << "The student doesn't have access to this program"
        end
      end
    end
    insufficient_access_message.join('. ').concat('.') if insufficient_access_message.present?
  end

  private def insufficient_access_students_user_licenses
    if defined? @insufficient_access_students_user_licenses
      return @insufficient_access_students_user_licenses
    end

    students_with_insufficient_access = students.reject(&:sufficient_access?)
    # We reject the the grace period ones, since we are already handling them in
    # another way.
    @insufficient_access_students_user_licenses = Maestro::UserLicense.all_for_users_in_program(
      students_with_insufficient_access.pluck(:guid), @program.id
    ).reject(&:grace_period?).group_by(&:user_guid)
  end

  private def grace_period_days_remaining(student)
    grace_period_user_license = student_user_licenses[student.guid].detect(&:grace_period?)
    [(grace_period_user_license.expiration_date - Time.zone.today).to_i, 0].max
  end

  private def student_user_licenses
    @student_user_licenses ||= Hash.new do |hash, student_guid|
      hash[student_guid] = Maestro::UserLicense.all_for_user_and_program(
        student_guid, @program.id
      )
    end
  end

  private def user_guids_with_grace_periods
    @user_guids_with_grace_periods ||= course_grace_periods.map(&:user_guid)
  end

  private def course_grace_periods
    return @course_grace_periods if defined? @course_grace_periods

    @course_grace_periods = Maestro::StudentGracePeriod.all_for_course(course.guid)
  end

  private def last_submissions_by_student
    return @last_submissions_by_student if defined? @last_submissions_by_student
    results = Attempt.select('max(updated_at) as latest_submission, user_id')
              .where(section_id: @section_id, user_id: students.to_a)
              .group(:user_id)
    @last_submissions_by_student = results.each_with_object({}) do |result, memo|
      memo[result.user_id] = result.latest_submission.in_time_zone
    end
  end

  private def course
    @course ||= Section.joins(:course).includes(:course).where(id: @section_id).first.course
  end

  private def course_licenses
    @course_licenses ||= Maestro::CourseLicense.all(course.guid).map(&:license_group)
  end

  private def student_user_licenses_with_grace_period?(student_guid)
    user_guids_with_grace_periods.include?(student_guid) &&
    student_user_licenses[student_guid].detect(&:grace_period?).present? &&
    are_expiration_date_equals?(student_guid)
  end

  private def are_expiration_date_equals?(student_guid)
    user_licenses = student_user_licenses[student_guid]
    grace_period_license = user_licenses&.detect(&:grace_period?)
    user_licenses.all? do |user_license|
      user_license.expiration_date == grace_period_license&.expiration_date
    end
  end

  private def all_user_licenses_have_expired?(student_guid)
    user_licenses = student_user_licenses[student_guid].reject(&:grace_period?)
    today = Date.today
    user_licenses.all? do |user_license|
      user_license.expiration_date < today
    end
  end

  private def section_immediate_access_revokes(section_guid)
    @section_immediate_access_revokes ||= Maestro::UserAccess.immediate_access_revoke_list(section_guid)['user_guids'] || []
  end
end
