class GradebookStudent < BasicObject
  attr_accessor :sections
  attr_reader :student, :grace_period, :program_id

  # Initializes a new instance of the GradebookStudent class.
  #
  # @param student [Student] The student object.
  # @param grace_period [Integer] The grace period in days.
  # @param program_id [Integer] The program ID.
  # @param sections [Array] An array of sections the student may be enrolled in,
  #                         this should be limited by an instructor's focus on a
  #                         given course or section.
  # @return [GradebookStudent] The initialized GradebookStudent object.
  def initialize(student, grace_period, program_id, sections = [])
    @student = student
    @grace_period = grace_period
    @program_id = program_id
    self.sections = sections
  end

  def ==(other_student)
    other_student.class == ::Student && other_student.id == self.id
  end

  # Returns sections the student is enrolled in, sorted by name.
  #
  # Example: [<Section:0x00007fd9a10b3a80>, <Section:0x00007fd9a10b3a90>]
  #
  # @return [Array<Section>] The sections the gradebook student is enrolled in.
  def enrolled_sections_by_name
    sections.select do |section|
      potential_enrollment_section_ids.include?(section.id)
    end.sort_by(&:name)
  end

  def sufficient_access?
    active_enrollment && (active_enrollment.sufficient_access || grace_period)
  end

  def self.decorate(students, program, sections = [])
    input_was_array = students.is_a?(::Array)
    students = Array(students)
    active_grace_periods =
      active_grace_periods_by_student(students, program.id)

    decorated_students = students.map do |student|
      new(student, active_grace_periods[student.guid], program.id, sections)
    end

    input_was_array ? decorated_students : decorated_students.first
  ensure
    # Clear cache after use to prevent memory leaks
    clear_license_cache
  end

  # Checks if any student lacks access (enrollment or grace period)
  def self.has_access_problem?(students, program, sections = [])
    return false if program.nil? || students.to_a.empty?

    enrollments_data = bulk_enrollments_for_access_check(students, sections, program)
    return false if enrollments_data.empty?

    insufficient_access_students = find_insufficient_access_students(enrollments_data)
    return false if insufficient_access_students.empty?

    check_grace_periods(students, insufficient_access_students, program.id)
  ensure
    # Clear cache after use to prevent memory leaks
    clear_license_cache
  end

  def self.enrollment_scope(sections, program_id, base_scope = ::Enrollment.active)
    return base_scope.by_program(program_id) if sections.to_a.empty?

    base_scope.where(section_id: sections)
  end

  # Bulk enrollment query for access checking with ordering
  def self.bulk_enrollments_for_access_check(students, sections, program)
    student_ids = Array(students).compact.map(&:id)
    return {} if student_ids.empty?

    enrollment_scope(sections, program.id)
      .where(user_id: student_ids)
      .order(:id)
      .group_by(&:user_id)
      .transform_values(&:last)
  end

  # Grace period check
  def self.batch_active_grace_periods(student_guids, program_id)
    return {} if student_guids.empty?

    licenses = all_user_licenses(student_guids, program_id)
    build_grace_period_mapping(student_guids, licenses)
  end

  def self.active_grace_periods_by_student(students, program_id)
    id_to_guid = students.to_h { |s| [s.id, s.guid] }

    all_user_licenses(students.map(&:guid), program_id).each_with_object({}) do |license, memo|
      next unless license.grace_period? && !license.expired?

      guid = id_to_guid[license.user_id]
      memo[guid] = license if guid
    end
  end
  private_class_method :active_grace_periods_by_student

  def self.find_insufficient_access_students(enrollments_data)
    enrollments_data.select do |_student_id, enrollment|
      enrollment.nil? || enrollment.sufficient_access == false
    end.keys
  end
  private_class_method :find_insufficient_access_students

  def self.check_grace_periods(students, insufficient_access_students, program_id)
    # Build efficient lookup hash: student_id => student_guid
    students_by_id = students.each_with_object({}) do |student, hash|
      hash[student.id] = student.guid
    end

    # Get GUIDs for students with insufficient access
    student_guids = insufficient_access_students.map { |id| students_by_id[id] }.compact

    return false if student_guids.empty?

    grace_periods_status = batch_active_grace_periods(student_guids, program_id)

    # Check if any student lacks grace period
    insufficient_access_students.any? do |student_id|
      student_guid = students_by_id[student_id]
      !grace_periods_status[student_guid]
    end
  end
  private_class_method :check_grace_periods

  def self.build_grace_period_mapping(student_guids, licenses)
    # Get guids that have active grace periods
    guids_with_grace = licenses
      .select { |license| license.grace_period? && !license.expired? }
      .map(&:user_guid)
      .to_set

    # Map each student guid to true/false for grace period status
    student_guids.each_with_object({}) do |guid, result|
      result[guid] = guids_with_grace.include?(guid)
    end
  end
  private_class_method :build_grace_period_mapping

  # It is going to be painful to hit this more than once, so don't.
  def self.all_user_licenses(student_guids, program_id)
    @all_user_licenses ||= {}

    sorted_guids = student_guids.sort
    base_key = "#{program_id}:#{sorted_guids.join('|')}"
    hash_key = ::Digest::SHA256.hexdigest(base_key)

    existing_values = @all_user_licenses[hash_key]
    return existing_values if existing_values

    @all_user_licenses[hash_key] = ::Maestro::UserLicense.all_for_users_in_program(
      student_guids, program_id
    )
  end
  private_class_method :all_user_licenses

  def self.clear_license_cache
    @all_user_licenses = nil
  end
  private_class_method :clear_license_cache

  # NOTE: This can safely use each student's first active enrollment for the
  #       specified sections because this is used in the context of a specific
  #       course and the enrollment is only used to determine course access,
  #       which should be identical for all sections of a given course.
  #       Using this with a mix of programs or courses would require changes.
  private def active_enrollment
    @active_enrollment ||= potential_enrollments.first
  end

  private def potential_enrollments
    ::GradebookStudent.enrollment_scope(sections,
     program_id, student.enrollments.active )
  end

  # Returns an array of section IDs for potential enrollments.
  #
  # @return [Array<Integer>] The section IDs for potential enrollments.
  private def potential_enrollment_section_ids
    @potential_enrollment_section_ids ||= potential_enrollments.map(&:section_id)
  end

  private def respond_to_missing?(method, include_private = false)
    student.respond_to?(method, include_private)
  end

  private def method_missing(method, ...)
    student.__send__(method, ...)
  end
end
